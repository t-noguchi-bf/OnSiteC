// #7 キャンペーン：サンプルのキャンペーンと案内した会員を作り、期間中の購入を登録する（先に 00〜04 を実行する）
// 親キャンペーンは集計用（無効）。店舗ごとの子キャンペーンが有効で、ポイント履歴が自動で紐づく。
// 対象店舗が空欄の有効なキャンペーンは「全店キャンペーン」として、店舗の子キャンペーンが無いときに紐づく。
if ([SELECT COUNT() FROM Campaign WHERE Name LIKE '秋のブレンドフェア%' OR Name = '年末ギフトキャンペーン'] == 0) {
    Campaign autumn = new Campaign(Name = '秋のブレンドフェア', IsActive = false, Type = 'Other',
        StartDate = Date.today().addDays(-40), EndDate = Date.today().addDays(-10), BudgetedCost = 150000, ActualCost = 120000);
    Campaign gift = new Campaign(Name = '年末ギフトキャンペーン', IsActive = true, Type = 'Other',
        StartDate = Date.today().addDays(-7), EndDate = Date.today().addDays(60), BudgetedCost = 300000);
    insert new List<Campaign>{autumn, gift};

    Map<String, String> storeLabels = new Map<String, String>{'Shibuya' => '渋谷店', 'Shinjuku' => '新宿店', 'Jiyugaoka' => '自由が丘店'};
    Map<String, Campaign> children = new Map<String, Campaign>();
    for (String s : storeLabels.keySet()) {
        Campaign c = new Campaign(Name = '秋のブレンドフェア_' + storeLabels.get(s), ParentId = autumn.Id, IsActive = true, Type = 'Other',
            StartDate = autumn.StartDate, EndDate = autumn.EndDate, ActualCost = 40000);
        c.put('Store__c', s);
        children.put(s, c);
    }
    insert children.values();

    Map<String, PointCard__c> cards = new Map<String, PointCard__c>();
    for (PointCard__c pc : [SELECT Id, Member__c, Member__r.Email FROM PointCard__c]) cards.put(pc.Member__r.Email, pc);

    // 案内した会員（状況は既定の「送信済み」）
    insert new List<CampaignMember>{
        new CampaignMember(CampaignId = children.get('Shibuya').Id, ContactId = cards.get('sho.tanaka@example.com').Member__c),
        new CampaignMember(CampaignId = children.get('Shinjuku').Id, ContactId = cards.get('daisuke.watanabe@example.com').Member__c),
        new CampaignMember(CampaignId = children.get('Jiyugaoka').Id, ContactId = cards.get('misaki.sato@example.com').Member__c),
        new CampaignMember(CampaignId = children.get('Jiyugaoka').Id, ContactId = cards.get('yumi.takahashi@example.com').Member__c),
        new CampaignMember(CampaignId = gift.Id, ContactId = cards.get('kenta.suzuki@example.com').Member__c),
        new CampaignMember(CampaignId = gift.Id, ContactId = cards.get('mayu.ito@example.com').Member__c)
    };

    // 期間中の購入（キャンペーン欄は空欄で登録し、フローで自動設定させる）
    // 会員のメール, 店舗, 購入金額, 何日前
    List<Object[]> rows = new List<Object[]>{
        new Object[]{'sho.tanaka@example.com', 'Shibuya', 3240, 35},
        new Object[]{'sho.tanaka@example.com', 'Shibuya', 2160, 14},
        new Object[]{'daisuke.watanabe@example.com', 'Shinjuku', 4320, 30},
        new Object[]{'misaki.sato@example.com', 'Jiyugaoka', 5400, 28},
        new Object[]{'misaki.sato@example.com', 'Jiyugaoka', 1680, 12},
        new Object[]{'mayu.ito@example.com', 'Shibuya', 1980, 25},
        new Object[]{'kenta.suzuki@example.com', 'Online', 2980, 5},
        new Object[]{'mayu.ito@example.com', 'Futakotamagawa', 6480, 3},
        new Object[]{'yumi.takahashi@example.com', 'Kichijoji', 3780, 2},
        new Object[]{'daisuke.watanabe@example.com', 'Shinjuku', 2160, 1}
    };
    List<PointTransaction__c> txs = new List<PointTransaction__c>();
    for (Object[] r : rows) {
        Integer amount = (Integer) r[2];
        txs.add(new PointTransaction__c(PointCard__c = cards.get((String) r[0]).Id, Type__c = 'Earn', PurchaseAmount__c = amount,
            Points__c = Math.floor(amount / 100.0), Store__c = (String) r[1], TransactionDate__c = Date.today().addDays(-(Integer) r[3])));
    }
    // 古い日付から順に1件ずつ登録し、リピートの判定を実際の運用と同じ順序にする
    for (PointTransaction__c t : txs) insert t;
}

// 補正：キャンペーン期間中に購入した、案内済みの会員を「レスポンスあり」にする（フロー修正前に登録したサンプル用。何度実行してもよい）
List<CampaignMember> toRespond = new List<CampaignMember>();
for (CampaignMember cm : [SELECT Id, ContactId, CampaignId FROM CampaignMember WHERE HasResponded = false]) {
    Integer bought = [SELECT COUNT() FROM PointTransaction__c
                      WHERE PointCard__r.Member__c = :cm.ContactId
                      AND (Campaign__c = :cm.CampaignId OR Campaign__r.ParentId = :cm.CampaignId)];
    if (bought > 0) {
        cm.Status = 'Responded';
        toRespond.add(cm);
    }
}
update toRespond;
