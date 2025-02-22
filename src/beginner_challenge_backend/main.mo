import Map "mo:map/Map";
import Result "mo:base/Result";
import Nat "mo:base/Nat";
import Text "mo:base/Text";
import Principal "mo:base/Principal";
import Vector "mo:vector";
import {phash; nhash} "mo:map/Map";

actor {
    stable var nextId = 0;
    stable var userIdMap : Map.Map<Principal, Nat> = Map.new<Principal, Nat>();
    stable var userProfileMap : Map.Map<Nat, Text> = Map.new<Nat, Text>();
    stable var userResultMap : Map.Map<Nat, Vector.Vector<Text>> = Map.new<Nat, Vector.Vector<Text>>();
    
    public query ({ caller }) func getUserProfile() : async Result.Result<{ id : Nat; name : Text }, Text> {
        
        switch(Map.get(userIdMap, phash, caller))
        {
            //existing user
            case(?idFound) {
                let name = switch (Map.get(userProfileMap, nhash, idFound)) {
                    case (?value) value; 
                    case null "Default Value"; 
                    };
                return #ok({id = idFound; name = name });
            };
            //creating new user
            case(_) {
                return #err("User not found");
            }
        };
        
    };

    public shared ({ caller }) func setUserProfile(name : Text) : async Result.Result<{ id : Nat; name : Text }, Text> {

        switch(Map.get(userIdMap, phash, caller))
        {
            //existing  user 
            case(?idFound) {
                Map.set(userProfileMap, nhash, idFound, name);
                return #ok({id = idFound; name = name});
            };
            //creating new user 
            case(_) {
                Map.set(userIdMap, phash, caller, nextId);
                nextId += 1;
                Map.set(userProfileMap, nhash, nextId - 1, name);
                return #ok({ id = nextId - 1; name = name});
            }
        };
    };

    public shared ({ caller }) func addUserResult(result : Text) : async Result.Result<{ id : Nat; results : [Text] }, Text> {
        
        switch(Map.get(userIdMap, phash, caller))
        {
            //existing  user 
            case(?idFound) {
                let resultsOpt = Map.get(userResultMap, nhash, idFound);
                let results : Vector.Vector<Text> = switch resultsOpt {
                    case null Vector.new<Text>();
                    case (?resultsFound) {resultsFound;};
                };
                
                Vector.add(results, result);
                Map.set(userResultMap, nhash, idFound, results);
                return #ok({id = idFound; results = Vector.toArray(results)});
            };
            //user not found 
            case(_) {
                return #err("User was not found");
            };
        };
    };

    public query ({ caller }) func getUserResults() : async Result.Result<{ id : Nat; results : [Text] }, Text> {
        switch(Map.get(userIdMap, phash, caller))
        {
            //existing  user 
            case(?idFound) {
                let resultsOpt = Map.get(userResultMap, nhash, idFound);
                let results : Vector.Vector<Text> = switch resultsOpt {
                    case null Vector.new<Text>();
                    case (?resultsFound) {resultsFound;};
                };

                return #ok({id = idFound; results = Vector.toArray(results)});
            };
            //user not found 
            case(_) {
                return #err("User was not found");
            };
        };
    };
};
