import ballerina/http;

type Data record {|
    int id;
|};

type Player record {|
    *Data;
    string name;
    Country country;
|};

type Country record {|
    *Data;
    string name;
|};

type ImageUrl record {|
    string url;
|};

service / on new http:Listener(9090) {
    resource function get player(int id) returns Player {
        return createPlayerWithId(id);
    }
}

service /storage on new http:Listener(9000) {
    resource function get image(int id) returns ImageUrl {
        string url = string `https://s3.amazonaws.com/my-bucket/image/${id}`;
        return { url };
    }
}

isolated function createPlayerWithId(int id) returns Player {
    return {id, name: string `random player ${id}`, country: {id: 0, name: "random country"}};
}

type Team1 record {|
    string name;
    int score;
    int wickets;
    int overs;
|};

type Score1 record {|
    Team1 battingTeam;
    Team1 bowlingTeam;
|};

isolated function createScore1() returns Score1 {
    return {
        battingTeam: {name: "batting team", score: 100, wickets: 2, overs: 10},
        bowlingTeam: {name: "bowling team", score: 50, wickets: 5, overs: 5}
    };
}

type Team2 record {|
    string name;
    record {|
        string name;
        int score;
        int wickets;
        int overs;
    |}[] players;
|};

type Score2 record {|
    Team2 battingTeam;
    Team2 bowlingTeam;
|};

isolated function createScore2() returns Score2 {
    return {
        battingTeam: {name: "batting team", players: [{name: "player1", score: 50, wickets: 1, overs: 5}]},
        bowlingTeam: {name: "bowling team", players: [{name: "player2", score: 25, wickets: 2, overs: 5}]}
    };
}

service / on new http:Listener(9091) {
    resource function get score(int id) returns Score1 {
        return createScore1();
    }
}

service / on new http:Listener(9092) {
    resource function get score(int id) returns Score2 {
        return createScore2();
    }
}
