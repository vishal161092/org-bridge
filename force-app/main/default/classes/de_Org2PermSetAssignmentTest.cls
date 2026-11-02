@IsTest
private class de_Org2PermSetAssignmentTest {

    private class MockSuccess implements HttpCalloutMock {
        private Integer callCount = 0;

        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            callCount++;

            if (req.getMethod() == 'GET') {
                res.setStatusCode(200);
                res.setBody('{"records":[{"Id":"005000000000001"}]}');
            } else {
                res.setStatusCode(201);
                res.setBody('{"id":"0Pa000000000001","success":true}');
            }
            return res;
        }
    }

    private class MockUserNotFound implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(200);
            res.setBody('{"records":[]}');
            return res;
        }
    }

    private class MockAssignmentFailed implements HttpCalloutMock {
        private Integer callCount = 0;

        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            callCount++;

            if (req.getMethod() == 'GET') {
                res.setStatusCode(200);
                res.setBody('{"records":[{"Id":"005000000000001"}]}');
            } else {
                res.setStatusCode(400);
                res.setBody('[{"message":"duplicate value found","errorCode":"DUPLICATE_VALUE"}]');
            }
            return res;
        }
    }

    @IsTest
    static void testSuccessfulAssignment() {
        Test.setMock(HttpCalloutMock.class, new MockSuccess());

        de_Org2PermSetAssignment.Request req = new de_Org2PermSetAssignment.Request();
        req.username = 'testuser@example.com';
        req.permissionSetName = 'My_Perm_Set';

        List<de_Org2PermSetAssignment.Response> results =
            de_Org2PermSetAssignment.assignPermissionSets(new List<de_Org2PermSetAssignment.Request>{ req });

        System.assertEquals(1, results.size());
        System.assertEquals(true, results[0].success);
        System.assertNotEquals(null, results[0].assignmentId);
        System.assertEquals('Permission set assigned successfully.', results[0].message);
    }

    @IsTest
    static void testMissingFields() {
        de_Org2PermSetAssignment.Request req = new de_Org2PermSetAssignment.Request();

        List<de_Org2PermSetAssignment.Response> results =
            de_Org2PermSetAssignment.assignPermissionSets(new List<de_Org2PermSetAssignment.Request>{ req });

        System.assertEquals(1, results.size());
        System.assertEquals(false, results[0].success);
        System.assert(results[0].message.contains('username'));
        System.assert(results[0].message.contains('permissionSetName'));
    }

    @IsTest
    static void testUserNotFound() {
        Test.setMock(HttpCalloutMock.class, new MockUserNotFound());

        de_Org2PermSetAssignment.Request req = new de_Org2PermSetAssignment.Request();
        req.username = 'nobody@example.com';
        req.permissionSetName = 'My_Perm_Set';

        List<de_Org2PermSetAssignment.Response> results =
            de_Org2PermSetAssignment.assignPermissionSets(new List<de_Org2PermSetAssignment.Request>{ req });

        System.assertEquals(1, results.size());
        System.assertEquals(false, results[0].success);
        System.assert(results[0].message.contains('Could not find user'));
    }

    @IsTest
    static void testAssignmentCalloutFailed() {
        Test.setMock(HttpCalloutMock.class, new MockAssignmentFailed());

        de_Org2PermSetAssignment.Request req = new de_Org2PermSetAssignment.Request();
        req.username = 'testuser@example.com';
        req.permissionSetName = 'My_Perm_Set';

        List<de_Org2PermSetAssignment.Response> results =
            de_Org2PermSetAssignment.assignPermissionSets(new List<de_Org2PermSetAssignment.Request>{ req });

        System.assertEquals(1, results.size());
        System.assertEquals(false, results[0].success);
        System.assert(results[0].message.contains('Callout failed'));
    }

    @IsTest
    static void testNullRequest() {
        List<de_Org2PermSetAssignment.Response> results =
            de_Org2PermSetAssignment.assignPermissionSets(null);
        System.assertEquals(0, results.size());
    }
}
