import ballerina/http;
import ballerina/websocket;
import ballerina/io;
import ballerina/lang.runtime;

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
    final http:Client playerInfoClient = checkpanic new ("http://localhost:9090");
    final http:Client storageService = checkpanic new ("http://localhost:9000");

    isolated resource function get player(int playerId) returns Player|error {
        PlayerInfo info = check self.playerInfoClient->/player(id = playerId);
        ImageUrlRes imageUrl = check self.storageService->/image(id = playerId);
        var {name, country, id} = info;
        return {name, country, id, imageUrl: imageUrl.url};
    }
}

// Live score service
service / on new websocket:Listener(8081) {
    resource function get .(int gameId) returns websocket:Service {
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

type PlayerData record {
    string name;
    int score;
    int wickets;
    int overs;
};

type TeamData record {
    string name;
    PlayerData[] players;
};

type LiveScoreService2Res record {
    TeamData battingTeam;
    TeamData bowlingTeam;
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
    final http:Client liveScore1Client = checkpanic new ("http://localhost:9091");
    final http:Client liveScore2Client = checkpanic new ("http://localhost:9092");
    final int gameId;
    function init(int gameId) {
        self.gameId = gameId;
    }

    remote function onMessage(websocket:Caller caller, ScoreCommand scoreCommand) returns LiveScore|error? {
        match scoreCommand.command {
            "Next" => {
                return self.getScore();
            }
            "Close" => {
                // Cleanup any resources
                return ();
            }
            _ => {
                return error("Invalid command");
            }
        }
    }

    private function getScore() returns LiveScore|error {
        // FIXME: why can't this directly capture the client
        http:Client c1 = self.liveScore1Client;
        http:Client c2 = self.liveScore2Client;
        worker w1 returns LiveScore|error {
            LiveScoreService2Res res = check c1->/score(id = self.gameId);
            io:println(res);
            return self.fromScoreService2(res);
        }
        worker w2 returns LiveScore|error {
            LiveScoreService2Res res = check c2->/score(id = self.gameId);
            io:println(res);
            runtime:sleep(1000);
            return self.fromScoreService2(res);
        }
        return wait w2 | w1;
    }

    private function fromScoreService1(LiveScoreService1Res res) returns LiveScore {
        var {name: battingTeam, score} = res.battingTeam;
        var {name: bowlingTeam, wickets, overs} = res.bowlingTeam;
        return {battingTeam, bowlingTeam, score, wickets, overs};
    }

    private function fromScoreService2(LiveScoreService2Res res) returns LiveScore {
        int score = res.battingTeam.players.reduce(
            function(int currentScore, PlayerData player) returns int {
            return currentScore + player.score;
        }, 0);
        // FIXME: why below don't work
        // int score1 = res.battingTeam.players.reduce((int currentScore, PlayerData player) => currentScore + player.score        , 0 );
        var { overs, wickets } = res.bowlingTeam.players.reduce(function(BowlingTeamStats stats, PlayerData player) returns BowlingTeamStats {
            return {overs: stats.overs + player.overs, wickets: stats.wickets + player.wickets};
        }, {overs: 0, wickets: 0});
        return { battingTeam: res.battingTeam.name, bowlingTeam: res.bowlingTeam.name, score, wickets, overs };
    }
}

type BowlingTeamStats record {|
    int overs;
    int wickets;
|};
