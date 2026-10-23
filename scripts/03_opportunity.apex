// #5 法人商談：サンプルの法人取引先と商談を作る（先に 00_assign_permsets.apex を実行する）
if ([SELECT COUNT() FROM Opportunity WHERE Name LIKE '【サンプル】%'] == 0) {
    // 取引先名, 業種の説明
    List<String[]> corps = new List<String[]>{
        new String[]{'吉祥寺デザイン事務所', 'オフィス'},
        new String[]{'自由が丘パティスリー', '飲食店'},
        new String[]{'二子玉川クリニック', 'オフィス'},
        new String[]{'渋谷テックラボ株式会社', 'オフィス'},
        new String[]{'新宿ビストロ月影', '飲食店'},
        new String[]{'池袋ブックカフェ', '飲食店'}
    };
    List<Account> accs = new List<Account>();
    for (String[] c : corps) accs.add(new Account(Name = c[0], Description = c[1]));
    insert accs;

    // 取引先の番号, 店舗, 種別, フェーズ, 金額, 月額見込み, 何日後に完了予定
    List<Object[]> rows = new List<Object[]>{
        new Object[]{0, 'Kichijoji', 'OfficeSubscription', '提案', 240000, 20000, 20},
        new Object[]{1, 'Jiyugaoka', 'Wholesale', 'Negotiation', 960000, 80000, 10},
        new Object[]{2, 'Futakotamagawa', 'OfficeSubscription', 'Hearing', 180000, 15000, 40},
        new Object[]{3, 'Shibuya', 'OfficeSubscription', 'Quote', 600000, 50000, 15},
        new Object[]{3, 'Shibuya', 'OfficeSubscription', 'ClosedWon', 360000, 30000, -5},
        new Object[]{4, 'Shinjuku', 'Wholesale', 'Hearing', 720000, 60000, 45},
        new Object[]{4, 'Shinjuku', 'Wholesale', 'ClosedLost', 480000, 40000, -10},
        new Object[]{5, 'Ikebukuro', 'Wholesale', '提案', 420000, 35000, 25},
        new Object[]{0, 'Kichijoji', 'Wholesale', 'Quote', 300000, 25000, 30}
    };
    List<Opportunity> opps = new List<Opportunity>();
    for (Object[] r : rows) {
        Account a = accs[(Integer) r[0]];
        String typeLabel = r[2] == 'OfficeSubscription' ? 'オフィス定期便' : '業務用卸';
        Opportunity o = new Opportunity(
            Name = '【サンプル】' + a.Name + '_' + typeLabel,
            AccountId = a.Id, Type = (String) r[2], StageName = (String) r[3],
            Amount = (Integer) r[4], CloseDate = Date.today().addDays((Integer) r[6]));
        o.put('Store__c', r[1]);
        o.put('MonthlyAmount__c', (Integer) r[5]);
        opps.add(o);
    }
    insert opps;
}
