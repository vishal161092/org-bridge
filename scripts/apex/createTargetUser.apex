// Anonymous Apex: create a User in the TARGET org through the Named Credential "Target_Org_NC".
// Run in the SOURCE org:  sf apex run --file scripts/apex/createTargetUser.apex --target-org <source-alias>
// Replace the placeholders below (profile must exist in the target org).
de_Org2UserProvisioning.Request req = new de_Org2UserProvisioning.Request();
req.firstName = '<FIRST_NAME>';
req.lastName = '<LAST_NAME>';
String uniq = String.valueOf(DateTime.now().getTime());
req.email = 'new.user.' + uniq + '@example.com';
req.profileName = 'Standard User';
req.alias = 'newusr';
// req.username = '<optional explicit username in the target org>';
List<de_Org2UserProvisioning.Response> responses =
    de_Org2UserProvisioning.createUsers(new List<de_Org2UserProvisioning.Request>{ req });
System.debug('ORG2_CREATE_RESULT=' + JSON.serialize(responses));
