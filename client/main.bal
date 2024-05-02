import ballerina/websocket;
import ballerina/io;

type ScoreCommand record {
    "Next"|"Close" command;
};

public function main() returns error? {
    websocket:Client scoreClient = check new ("ws://localhost:8081/?gameId=0");
    check scoreClient->writeMessage({command: "Next"});
    anydata res = check scoreClient->readMessage();
    io:println(res);
}
