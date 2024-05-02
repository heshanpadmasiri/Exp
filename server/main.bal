import ballerina/websocket;
import ballerina/http;
import ballerina/io;

type Country record {
    string name;
    int id;
};

type PlayerInfo record {
    string name;
    Country country;
    int id;
};

type ImageUrlRes record {
    string url;
};

type Player record {|
    *PlayerInfo;
    string imageUrl;
|};

// Player information service
service / on new http:Listener(8080) {
    final http:Client playerInfoClient = checkpanic new("http://localhost:9090");
    final http:Client storageService = checkpanic new("http://localhost:9000");

    isolated resource function get player(int playerId) returns Player|error {
        PlayerInfo info = check self.playerInfoClient->/player(id = playerId);
        ImageUrlRes imageUrl = check self.storageService->/image(id = playerId);
        var { name, country, id } = info;
        return { name, country, id, imageUrl: imageUrl.url };
    }
}

// Live score service
service / on new websocket:Listener(8081) {
    resource function get .(int gameId) returns websocket:Service {
        io:println("Game ID: ", gameId);
        return new ScoreService(gameId);
    }
}

type ScoreCommand record {
    "Next"|"Close" command;
};

type BattingTeam record {
    string name;
    int score;
    int wickets;
    int overs;
};

type BowlingTeam record {
    string name;
    int score;
    int wickets;
    int overs;
};

type LiveScoreService1Res record {
    BattingTeam battingTeam;
    BowlingTeam bowlingTeam;
};

type LiveScore record {|
    string battingTeam;
    string bowlingTeam;
    int score;
    int wickets;
    int overs;
|};

service class ScoreService {
    *websocket:Service;
    final http:Client liveScore1Client = checkpanic new("http://localhost:9091");
    final int gameId;
    function init(int gameId) {
        self.gameId = gameId;
    }

    remote function onMessage(websocket:Caller caller, ScoreCommand scoreCommand) returns LiveScore|error? {
        io:println(scoreCommand);
        match scoreCommand.command {
            "Next" => {
                LiveScoreService1Res res = check self.liveScore1Client->/score(id=self.gameId);
                return self.fromScoreService1(res);
            }
            "Close" => {
                // TODO: close the connection
                return error("Unimplemented");
            }
            _ => {
                return error("Invalid command");
            }
        }
    }

    private function fromScoreService1(LiveScoreService1Res res) returns LiveScore {
        var { name: battingTeam, score, wickets, overs } = res.battingTeam;
        return { battingTeam, bowlingTeam: res.bowlingTeam.name, score, wickets, overs };
    }
}
