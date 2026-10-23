// #11 店舗の取引先、会員の付け替え、POS売上明細の取り込み（先に 00_assign_permsets.apex を実行する。何度実行してもよい）

// (1) 店舗を取引先として作る（取引先区分＝自社店舗）
Map<String, String> storeNames = new Map<String, String>{
    'Kichijoji' => '三日月珈琲 吉祥寺本店', 'Jiyugaoka' => '三日月珈琲 自由が丘店', 'Futakotamagawa' => '三日月珈琲 二子玉川店',
    'Shibuya' => '三日月珈琲 渋谷店', 'Shinjuku' => '三日月珈琲 新宿店', 'Ikebukuro' => '三日月珈琲 池袋店', 'Online' => '三日月珈琲 オンラインショップ'
};
Map<String, Account> storeAccounts = new Map<String, Account>();
for (Account a : [SELECT Id, Store__c FROM Account WHERE CustomerCategory__c = 'OwnStore']) storeAccounts.put(a.Store__c, a);
List<Account> newStores = new List<Account>();
for (String s : storeNames.keySet()) {
    if (!storeAccounts.containsKey(s)) {
        Account a = new Account(Name = storeNames.get(s), Description = '個人のお客様（会員）をまとめる店舗の取引先');
        a.put('Store__c', s);
        a.put('CustomerCategory__c', 'OwnStore');
        newStores.add(a);
        storeAccounts.put(s, a);
    }
}
Database.DMLOptions allow = new Database.DMLOptions();
allow.DuplicateRuleHeader.allowSave = true;
Database.insert(newStores, allow);

// (2) 「個人のお客様」取引先の会員を、よく行く店舗の取引先に移す
List<Contact> moves = new List<Contact>();
for (Contact c : [SELECT Id, Store__c FROM Contact WHERE Account.Name = '個人のお客様' AND Store__c != null]) {
    c.AccountId = storeAccounts.get(c.Store__c).Id;
    moves.add(c);
}
Database.update(moves, allow);

// (3) 既存のポイント履歴に会員を入れる（保存し直すとフローが動く）
update [SELECT Id FROM PointTransaction__c WHERE Contact__c = null];

// (4) 配布資料の「POS売上明細」ファイルを取り込む
if ([SELECT COUNT() FROM POSSale__c] == 0) {
    Map<String, String> storeByCode = new Map<String, String>{
        'S01' => 'Kichijoji', 'S02' => 'Jiyugaoka', 'S03' => 'Futakotamagawa', 'S04' => 'Shibuya', 'S05' => 'Shinjuku', 'S06' => 'Ikebukuro'
    };
    Map<String, String> payByLabel = new Map<String, String>{
        '現金' => 'Cash', 'クレジット' => 'Credit', '電子マネー' => 'EMoney', 'QRコード決済' => 'QR'
    };
    ContentVersion cv = [SELECT VersionData FROM ContentVersion WHERE Title = 'POS売上明細_2026年10月1日-14日' AND IsLatest = true LIMIT 1];
    List<String> lines = cv.VersionData.toString().replace('\r', '').split('\n');
    List<POSSale__c> sales = new List<POSSale__c>();
    for (Integer i = 1; i < lines.size(); i++) {
        if (String.isBlank(lines[i])) continue;
        // 取引番号,日時,店舗コード,店舗名,レジ番号,商品コード,商品名,内容量,数量,単価（税込）,金額（税込）,支払方法
        String[] f = lines[i].split(',');
        String[] dt = f[1].split(' ');
        String[] d = dt[0].split('-');
        String[] t = dt[1].split(':');
        sales.add(new POSSale__c(
            TransactionNo__c = f[0],
            SoldAt__c = Datetime.newInstance(Integer.valueOf(d[0]), Integer.valueOf(d[1]), Integer.valueOf(d[2]), Integer.valueOf(t[0]), Integer.valueOf(t[1]), 0),
            Store__c = storeByCode.get(f[2]), RegisterNo__c = f[4], ProductCode__c = f[5], ProductName__c = f[6], Size__c = f[7],
            Quantity__c = Decimal.valueOf(f[8]), UnitPrice__c = Decimal.valueOf(f[9]), Amount__c = Decimal.valueOf(f[10]),
            PaymentMethod__c = payByLabel.get(f[11])));
    }
    insert sales;

    // (5) 画面で見せるためのサンプル：店舗の明細の一部を、その店舗によく行くサンプル会員のカードで買ったことにする
    //     （元のPOSファイルにはお客様の情報が無い。会員とポイントのつながりを見せるための仮の紐づけ）
    Map<String, PointCard__c> cardByStore = new Map<String, PointCard__c>();
    for (PointCard__c pc : [SELECT Id, Member__r.Store__c FROM PointCard__c WHERE Member__r.Store__c != null]) cardByStore.put(pc.Member__r.Store__c, pc);
    Map<String, Integer> linked = new Map<String, Integer>();
    List<POSSale__c> toLink = new List<POSSale__c>();
    for (POSSale__c s : sales) {
        PointCard__c pc = cardByStore.get(s.Store__c);
        Integer n = linked.containsKey(s.Store__c) ? linked.get(s.Store__c) : 0;
        if (pc != null && n < 2) {
            s.PointCard__c = pc.Id;
            toLink.add(s);
            linked.put(s.Store__c, n + 1);
        }
    }
    update toLink;  // フローで会員が自動で入る

    // (6) 紐づけた売上に、ポイント履歴（付与）を作る（100円で1ポイント）
    List<PointTransaction__c> earns = new List<PointTransaction__c>();
    for (POSSale__c s : toLink) {
        earns.add(new PointTransaction__c(PointCard__c = s.PointCard__c, POSSale__c = s.Id, Type__c = 'Earn',
            Points__c = Math.floor(s.Amount__c / 100), PurchaseAmount__c = s.Amount__c, Store__c = s.Store__c,
            TransactionDate__c = s.SoldAt__c.date()));
    }
    insert earns;
}
