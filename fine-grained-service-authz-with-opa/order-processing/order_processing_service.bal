import ballerina/http;
import ballerina/runtime;
import ballerina/log;
import ballerina/io;

http:AuthProvider jwtAuthProvider = {
    scheme:"jwt",
    issuer:"wso2is",
    audience: "3VTwFk7u1i366wzmvpJ_LZlfAV4a",
    certificateAlias:"wso2carbon",
    trustStore: {
        path: "order-processing/keys/truststore.p12",
        password: "wso2carbon"
    }
};

endpoint http:Client opa {
    url: "http://localhost:8181",
     secureSocket: {
        trustStore: {
            path: "order-processing/keys/truststore.p12",
            password: "wso2carbon"
        }
    }
};

endpoint http:SecureListener ep {
    port: 9008,
    authProviders:[jwtAuthProvider],

    secureSocket: {
        keyStore: {
            path: "order-processing/keys/keystore.p12",
            password: "wso2carbon"
        },
        trustStore: {
            path: "order-processing/keys/truststore.p12",
            password: "wso2carbon"
        }
    }
};

@http:ServiceConfig {
    basePath: "/order-processing",
    authConfig: {
        authentication: { enabled: true }
    }
}
service<http:Service> orderprocessing bind ep {
    @http:ResourceConfig {
        methods: ["POST"],
        path: "/orders",
        authConfig: {
            scopes: ["place-order"]
        }
    }
    placeOrder(endpoint caller, http:Request req) {
        setJWT(runtime:getInvocationContext().authContext.authToken);
        http:Request opaReq = new;
        json opaPayload = { "input" : { "method" : "GET", "path" : ["finance","salary"],"user": "bob2" }};
        opaReq.setJsonPayload(opaPayload, contentType = "application/json");
        var response = opa->post("/v1/data/authz/allow",opaReq);
        match response {
            http:Response resp => { 
                string log = "response from opa " + check resp.getPayloadAsString();
                log:printInfo(log);
                json success = {"status" : "order created successfully"};
                http:Response res = new;
                res.setPayload(success);
                _ = caller->respond(res);
            }
            error err => { 
                log:printError("call to the inventory endpoint failed.");
                json failure = {"status" : "failed to create a new order"};
                http:Response res = new;
                res.setPayload(failure);
                res.statusCode = 500;
                _ = caller->respond(res);
            }
        }        
    }
}

//function setToken(http:Request req) {
//    string authHeader = req.getHeader("Authorization");
//    runtime:getInvocationContext().authContext.scheme = "jwt";
//    runtime:getInvocationContext().authContext.authToken = authHeader.split(" ")[1];
//} 

function setJWT(string jwt) {
    runtime:getInvocationContext().authContext.scheme = "jwt";
    runtime:getInvocationContext().authContext.authToken = jwt;
}


