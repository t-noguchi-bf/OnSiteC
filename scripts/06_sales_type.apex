// #10 飛び込み営業とアップセル：サンプルデータの移行と追加（先に 00_assign_permsets.apex と 03_opportunity.apex を実行する。何度実行してもよい）

// (1) #5 で種別に入れていた オフィス定期便／業務用卸 を「商材」に移し、種別を 新規開拓／アップセル にする
Set<Id> wonAccounts = new Set<Id>();
for (Opportunity o : [SELECT AccountId FROM Opportunity WHERE IsWon = true AND AccountId != null]) wonAccounts.add(o.AccountId);
List<Opportunity> opps = [SELECT Id, Type, AccountId, IsWon FROM Opportunity WHERE Type IN ('OfficeSubscription', 'Wholesale')];
for (Opportunity o : opps) {
    o.put('ProductCategory__c', o.Type);
    o.Type = (!o.IsWon && wonAccounts.contains(o.AccountId)) ? 'Existing Business' : 'New Business';
}
update opps;

// (2) 法人の取引先に、担当店舗と法人区分を入れる（商談の店舗から）
Map<Id, Account> accs = new Map<Id, Account>();
for (Opportunity o : [SELECT AccountId, Store__c, ProductCategory__c FROM Opportunity WHERE Name LIKE '【サンプル】%' AND AccountId != null]) {
    Account a = new Account(Id = o.AccountId);
    a.put('Store__c', o.Store__c);
    a.put('CustomerCategory__c', o.ProductCategory__c == 'Wholesale' ? 'Restaurant' : 'Office');
    accs.put(a.Id, a);
}
update accs.values();

// (3) 飛び込み営業のリード（法人営業_案件一覧のうち、まだ商談になっていない会社）
if ([SELECT COUNT() FROM Lead WHERE LeadSource = 'DoorToDoor'] == 0) {
    // 会社名, 店舗, 担当スタッフ, 状況, 何日前に訪問, メモ
    List<String[]> rows = new List<String[]>{
        new String[]{'株式会社みどり建設', 'Shibuya', '佐々木', 'Contacted', '50', '来客用のコーヒー。電話で話しただけ。そのうち訪問'},
        new String[]{'グリーンデザイン株式会社', 'Shibuya', '佐々木', 'New', '38', '名刺交換のみ'},
        new String[]{'新宿ITソリューションズ', 'Shinjuku', '小林', 'Contacted', '24', 'フロア3つ分。社内で検討中らしい'},
        new String[]{'池袋シェアオフィス', 'Ikebukuro', '山田', 'Contacted', '14', 'ラウンジ用 豆とミルク。見積もりを出した'},
        new String[]{'吉祥寺こども歯科', 'Kichijoji', '中村', 'Unqualified', '30', '待合室用。院長がコーヒーを飲まないため見送り'}
    };
    List<Lead> leads = new List<Lead>();
    for (String[] r : rows) {
        Lead l = new Lead(Company = r[0], LastName = '（ご担当者）', LeadSource = 'DoorToDoor', Status = r[3], Description = r[5]);
        l.put('Store__c', r[1]);
        l.put('StaffName__c', r[2]);
        l.put('LastVisitDate__c', Date.today().addDays(-Integer.valueOf(r[4])));
        leads.add(l);
    }
    Database.DMLOptions dml = new Database.DMLOptions();
    dml.DuplicateRuleHeader.allowSave = true;
    Database.insert(leads, dml);
}

// (3b) 既存の取引先とリードに、照合用の会社名を入れる（保存し直すとフローが動く）
Database.DMLOptions allow = new Database.DMLOptions();
allow.DuplicateRuleHeader.allowSave = true;
Database.update([SELECT Id FROM Account], allow);
Database.update([SELECT Id FROM Lead WHERE IsConverted = false], allow);

// (4) 既存のお客様へのアップセル（種別・店舗は空欄で作り、フローで自動設定させる）
if ([SELECT COUNT() FROM Opportunity WHERE Name LIKE '【サンプル】%アップセル%'] == 0) {
    Account tech = [SELECT Id FROM Account WHERE Name = '渋谷テックラボ株式会社' LIMIT 1];
    Opportunity up = new Opportunity(Name = '【サンプル】渋谷テックラボ株式会社_アップセル（会議用ドリップバッグ）',
        AccountId = tech.Id, StageName = 'Hearing', CloseDate = Date.today().addDays(30), Amount = 120000);
    up.put('ProductCategory__c', 'OfficeSubscription');
    up.put('MonthlyAmount__c', 10000);
    insert up;
}
