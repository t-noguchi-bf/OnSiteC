// #4 問い合わせ：サンプルの会員とケースを作る（先に 00_assign_permsets.apex を実行する）
Group q = [SELECT Id FROM Group WHERE Type = 'Queue' AND DeveloperName = 'CS_HeadOffice'];

Account personal = [SELECT Id FROM Account WHERE Name = '個人のお客様' LIMIT 1];
List<String[]> members = new List<String[]>{
    new String[]{'佐藤', '美咲', 'misaki.sato@example.com'},
    new String[]{'鈴木', '健太', 'kenta.suzuki@example.com'},
    new String[]{'高橋', '由美', 'yumi.takahashi@example.com'},
    new String[]{'田中', '翔', 'sho.tanaka@example.com'},
    new String[]{'伊藤', '真由', 'mayu.ito@example.com'},
    new String[]{'渡辺', '大輔', 'daisuke.watanabe@example.com'}
};
Map<String, Contact> byEmail = new Map<String, Contact>();
for (Contact c : [SELECT Id, Email FROM Contact WHERE AccountId = :personal.Id]) byEmail.put(c.Email, c);
List<Contact> newContacts = new List<Contact>();
for (String[] m : members) {
    if (!byEmail.containsKey(m[2])) newContacts.add(new Contact(AccountId = personal.Id, LastName = m[0], FirstName = m[1], Email = m[2]));
}
insert newContacts;
for (Contact c : newContacts) byEmail.put(c.Email, c);

if ([SELECT COUNT() FROM Case WHERE Subject LIKE '【サンプル】%'] == 0) {
    // 件名, 会員のメール, 店舗, 種別, 受付方法, 状況
    List<String[]> rows = new List<String[]>{
        new String[]{'【サンプル】ギフト用の包装について', 'misaki.sato@example.com', 'Jiyugaoka', 'Gift', 'Store', 'New'},
        new String[]{'【サンプル】定期便の豆を変えたい', 'kenta.suzuki@example.com', 'Online', 'Subscription', 'Web', 'Working'},
        new String[]{'【サンプル】深煎りのおすすめを知りたい', 'yumi.takahashi@example.com', 'Kichijoji', 'Product', 'Store', 'Closed'},
        new String[]{'【サンプル】届いた豆の挽き方が違う', 'sho.tanaka@example.com', 'Online', 'Complaint', 'Email', 'Escalated'},
        new String[]{'【サンプル】カフェの混雑状況', 'mayu.ito@example.com', 'Futakotamagawa', 'Other', 'Phone', 'New'},
        new String[]{'【サンプル】年末ギフトの予約', 'daisuke.watanabe@example.com', 'Shibuya', 'Gift', 'Phone', 'Working'},
        new String[]{'【サンプル】200gの在庫確認', 'misaki.sato@example.com', 'Shinjuku', 'Product', 'Store', 'Closed'},
        new String[]{'【サンプル】ポイントカードを作りたい', 'kenta.suzuki@example.com', 'Ikebukuro', 'Other', 'Store', 'New'}
    };
    List<Case> cases = new List<Case>();
    for (String[] r : rows) {
        Case c = new Case(Subject = r[0], ContactId = byEmail.get(r[1]).Id, Type = r[3], Origin = r[4], Status = r[5]);
        c.put('Store__c', r[2]);
        if (r[5] == 'New') c.OwnerId = q.Id;
        cases.add(c);
    }
    insert cases;
}
