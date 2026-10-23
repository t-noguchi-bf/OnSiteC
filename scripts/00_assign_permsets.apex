// 三日月珈琲の権限セットを、実行したユーザーに割り当てる（何度実行してもよい）
Id meId = UserInfo.getUserId();
Set<Id> assigned = new Set<Id>();
for (PermissionSetAssignment a : [SELECT PermissionSetId FROM PermissionSetAssignment WHERE AssigneeId = :meId]) {
    assigned.add(a.PermissionSetId);
}
List<PermissionSetAssignment> toInsert = new List<PermissionSetAssignment>();
for (PermissionSet ps : [SELECT Id FROM PermissionSet WHERE Name LIKE 'MC%']) {
    if (!assigned.contains(ps.Id)) toInsert.add(new PermissionSetAssignment(AssigneeId = meId, PermissionSetId = ps.Id));
}
insert toInsert;
