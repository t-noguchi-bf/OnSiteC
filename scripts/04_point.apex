// #6 ポイント：サンプルの会員にカードを発行し、過去60日分のポイント履歴を作る（先に 00_assign_permsets.apex と 02_inquiry.apex を実行する）
if ([SELECT COUNT() FROM PointCard__c] == 0) {
    // 会員のメール, よく行く店舗, カード番号
    List<String[]> rows = new List<String[]>{
        new String[]{'misaki.sato@example.com', 'Jiyugaoka', '2026000000011'},
        new String[]{'kenta.suzuki@example.com', 'Online', '2026000000028'},
        new String[]{'yumi.takahashi@example.com', 'Kichijoji', '2026000000035'},
        new String[]{'sho.tanaka@example.com', 'Shibuya', '2026000000042'},
        new String[]{'mayu.ito@example.com', 'Futakotamagawa', '2026000000059'},
        new String[]{'daisuke.watanabe@example.com', 'Shinjuku', '2026000000066'}
    };
    Map<String, Contact> byEmail = new Map<String, Contact>();
    for (Contact c : [SELECT Id, Email FROM Contact WHERE Email LIKE '%@example.com']) byEmail.put(c.Email, c);
    List<Contact> contacts = new List<Contact>();
    List<PointCard__c> cards = new List<PointCard__c>();
    for (String[] r : rows) {
        Contact c = byEmail.get(r[0]);
        c.Store__c = r[1];
        contacts.add(c);
        cards.add(new PointCard__c(CardNumber__c = r[2], Member__c = c.Id, IssuedStore__c = r[1], IssuedDate__c = Date.today().addDays(-90)));
    }
    update contacts;
    insert cards;

    // 付与：各カードで、よく行く店舗を中心に、2〜3週間おきに購入する
    String[] stores = new String[]{'Kichijoji', 'Jiyugaoka', 'Futakotamagawa', 'Shibuya', 'Shinjuku', 'Ikebukuro', 'Online'};
    Integer[] amounts = new Integer[]{1280, 2160, 1680, 3240, 980, 4320, 1980};
    List<PointTransaction__c> earns = new List<PointTransaction__c>();
    for (Integer i = 0; i < cards.size(); i++) {
        for (Integer k = 0; k < 4; k++) {
            Integer amount = amounts[Math.mod(i + k, amounts.size())];
            String store = (k == 2) ? stores[Math.mod(i + 3, stores.size())] : cards[i].IssuedStore__c;
            earns.add(new PointTransaction__c(PointCard__c = cards[i].Id, Type__c = 'Earn', PurchaseAmount__c = amount,
                Points__c = Math.floor(amount / 100.0), Store__c = store, TransactionDate__c = Date.today().addDays(-60 + k * 16 + i)));
        }
    }
    insert earns;

    // 利用：3人がポイントを使う
    insert new List<PointTransaction__c>{
        new PointTransaction__c(PointCard__c = cards[0].Id, Type__c = 'Use', Points__c = -30, Store__c = 'Shibuya', TransactionDate__c = Date.today().addDays(-3)),
        new PointTransaction__c(PointCard__c = cards[2].Id, Type__c = 'Use', Points__c = -50, Store__c = 'Kichijoji', TransactionDate__c = Date.today().addDays(-2)),
        new PointTransaction__c(PointCard__c = cards[4].Id, Type__c = 'Use', Points__c = -20, Store__c = 'Online', TransactionDate__c = Date.today().addDays(-1))
    };
}
