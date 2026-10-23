// #3 共通：自分を本社所属にし、「個人のお客様」取引先を作る（先に 00_assign_permsets.apex を実行する）
User me = new User(Id = UserInfo.getUserId());
me.put('Store__c', 'HeadOffice');
update me;
if ([SELECT COUNT() FROM Account WHERE Name = '個人のお客様'] == 0) {
    insert new Account(Name = '個人のお客様', Description = '個人のお客様（会員）をまとめる取引先');
}
