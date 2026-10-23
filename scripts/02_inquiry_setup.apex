// #4 問い合わせ：自分を本社カスタマーサクセスのキューに入れる（02_inquiry.apex より先に実行する）
Id meId = UserInfo.getUserId();
Group q = [SELECT Id FROM Group WHERE Type = 'Queue' AND DeveloperName = 'CS_HeadOffice'];
if ([SELECT COUNT() FROM GroupMember WHERE GroupId = :q.Id AND UserOrGroupId = :meId] == 0) {
    insert new GroupMember(GroupId = q.Id, UserOrGroupId = meId);
}
