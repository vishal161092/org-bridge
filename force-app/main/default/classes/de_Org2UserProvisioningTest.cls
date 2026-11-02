@IsTest
private class de_Org2UserProvisioningTest {
    private class SuccessMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            if (req.getMethod() == 'GET' && req.getEndpoint().contains('/services/data/v66.0/query?q=')) {
                res.setStatusCode(200);
                res.setBody('{"totalSize":1,"done":true,"records":[{"attributes":{"type":"Profile"},"Id":"00eXXXXXXXXXXXX"}]}');
                return res;
            }

            System.assertEquals('POST', req.getMethod());
            System.assert(req.getEndpoint().contains('callout:Target_Org_NC/services/data/v66.0/sobjects/User'));
            res.setStatusCode(201);
            res.setBody('{"id":"005XXXXXXXXXXXXAAA","success":true,"errors":[]}');
            return res;
        }
    }

    private class ErrorMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            if (req.getMethod() == 'GET' && req.getEndpoint().contains('/services/data/v66.0/query?q=')) {
                res.setStatusCode(200);
                res.setBody('{"totalSize":1,"done":true,"records":[{"attributes":{"type":"Profile"},"Id":"00eXXXXXXXXXXXX"}]}');
                return res;
            }
            res.setStatusCode(400);
            res.setBody('[{"message":"Duplicate Username","errorCode":"DUPLICATE_USERNAME"}]');
            return res;
        }
    }

    @IsTest
    static void testCreateUsersSuccess() {
        Test.setMock(HttpCalloutMock.class, new SuccessMock());

        de_Org2UserProvisioning.Request requestPayload = new de_Org2UserProvisioning.Request();
        requestPayload.firstName = 'Alex';
        requestPayload.lastName = 'Tandon';
        requestPayload.email = 'alex@example.com';
        requestPayload.profileName = 'Standard User';
        requestPayload.username = 'alex.test@example.com.integration';
        requestPayload.alias = 'rtandon';

        Test.startTest();
        List<de_Org2UserProvisioning.Response> results =
            de_Org2UserProvisioning.createUsers(new List<de_Org2UserProvisioning.Request>{requestPayload});
        Test.stopTest();

        System.assertEquals(1, results.size());
        System.assertEquals(true, results[0].success);
        System.assertEquals('005XXXXXXXXXXXXAAA', results[0].targetUserId);
    }

    @IsTest
    static void testCreateUsersWithProfileNameSuccess() {
        Test.setMock(HttpCalloutMock.class, new SuccessMock());

        de_Org2UserProvisioning.Request requestPayload = new de_Org2UserProvisioning.Request();
        requestPayload.firstName = 'Alex';
        requestPayload.lastName = 'Tandon';
        requestPayload.email = 'alex.profile.name@example.com';
        requestPayload.profileName = 'Standard User';

        Test.startTest();
        List<de_Org2UserProvisioning.Response> results =
            de_Org2UserProvisioning.createUsers(new List<de_Org2UserProvisioning.Request>{requestPayload});
        Test.stopTest();

        System.assertEquals(1, results.size());
        System.assertEquals(true, results[0].success);
        System.assertEquals('005XXXXXXXXXXXXAAA', results[0].targetUserId);
    }

    @IsTest
    static void testCreateUsersValidationFailure() {
        de_Org2UserProvisioning.Request requestPayload = new de_Org2UserProvisioning.Request();
        requestPayload.firstName = 'NoLastName';

        List<de_Org2UserProvisioning.Response> results =
            de_Org2UserProvisioning.createUsers(new List<de_Org2UserProvisioning.Request>{requestPayload});

        System.assertEquals(1, results.size());
        System.assertEquals(false, results[0].success);
        System.assert(results[0].message.contains('Missing required fields'));
    }

    @IsTest
    static void testCreateUsersErrorFromTarget() {
        Test.setMock(HttpCalloutMock.class, new ErrorMock());

        de_Org2UserProvisioning.Request requestPayload = new de_Org2UserProvisioning.Request();
        requestPayload.firstName = 'Alex';
        requestPayload.lastName = 'Tandon';
        requestPayload.email = 'alex@example.com';
        requestPayload.profileName = 'Standard User';

        Test.startTest();
        List<de_Org2UserProvisioning.Response> results =
            de_Org2UserProvisioning.createUsers(new List<de_Org2UserProvisioning.Request>{requestPayload});
        Test.stopTest();

        System.assertEquals(1, results.size());
        System.assertEquals(false, results[0].success);
        System.assert(results[0].message.contains('Callout failed'));
    }
}
