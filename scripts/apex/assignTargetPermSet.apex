// Anonymous Apex: assign a Permission Set to an existing user in the TARGET org.
// Run in the SOURCE org:  sf apex run --file scripts/apex/assignTargetPermSet.apex --target-org <source-alias>
// Replace the placeholders below.
de_Org2PermSetAssignment.Request req = new de_Org2PermSetAssignment.Request();
req.username = '<TARGET_ORG_USERNAME>';
req.permissionSetName = '<PERMISSION_SET_API_NAME>';
List<de_Org2PermSetAssignment.Response> responses =
    de_Org2PermSetAssignment.assignPermissionSets(new List<de_Org2PermSetAssignment.Request>{ req });
System.debug('ORG2_ASSIGN_RESULT=' + JSON.serialize(responses));
