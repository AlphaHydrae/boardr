module Api.Model exposing
    ( ApiBoard
    , ApiGame
    , ApiGameDetailed
    , ApiGameList
    , ApiGameState(..)
    , ApiIdentity
    , ApiLocalAuthentication
    , ApiNodeStats
    , ApiPlayer
    , ApiPossibleActionList
    , ApiRoot
    , ApiStats
    , ApiUser
    , ApiUserWithToken
    , apiBoardDecoder
    , apiGameDecoder
    , apiGameDetailedDecoder
    , apiGameListDecoder
    , apiGameWithoutDetails
    , apiIdentityDecoder
    , apiLocalAuthenticationDecoder
    , apiPlayerDecoder
    , apiPossibleActionListDecoder
    , apiRootDecoder
    , apiStatsDecoder
    , apiUserDecoder
    , apiUserEncoder
    , apiUserWithTokenDecoder
    , apiUserWithoutToken
    )

import Dict exposing (Dict)
import Json.Decode as Decode exposing (Decoder, andThen, bool, dict, field, int, list, maybe, string)
import Json.Decode.Pipeline exposing (optional, required)
import Json.Encode as Encode


type alias ApiBoard =
    { data : List ApiPiece
    , dimensions : ( Int, Int )
    }


type alias ApiGame =
    { actionsLink : HalLink
    , boardLink : HalLink
    , createdAt : String
    , id : String
    , playersLink : HalLink
    , possibleActionsLink : HalLink
    , rules : String
    , selfLink : HalLink
    , state : ApiGameState
    , title : Maybe String
    , winners : Maybe (List ApiPlayer)
    }


type alias ApiGameDetailed =
    { actionsLink : HalLink
    , boardLink : HalLink
    , createdAt : String
    , id : String
    , players : List ApiPlayer
    , playersLink : HalLink
    , possibleActionsLink : HalLink
    , rules : String
    , selfLink : HalLink
    , state : ApiGameState
    , title : Maybe String
    , winners : Maybe (List ApiPlayer)
    }


type ApiGameState
    = WaitingForPlayers
    | Playing
    | Draw
    | Win


type alias ApiGameList =
    { games : List ApiGame
    , players : List ApiPlayer
    }


type alias ApiGameStats =
    { draw : Int
    , inactive : Int
    , playing : Int
    , waitingForPlayers : Int
    , win : Int
    }


type alias ApiIdentity =
    { createdAt : String
    , email : String
    , id : String
    , token : String
    }


type alias ApiLocalAuthentication =
    { token : String
    , user : ApiUser
    }


type alias ApiNodeStats =
    { gameServers : Int,
      swarmProcesses : Int
    }


type alias ApiPiece =
    { player : Int
    , position : ( Int, Int )
    }


type alias ApiPlayer =
    { createdAt : String
    , id : String
    , number : Int
    , gameLink : HalLink
    , selfLink : HalLink
    , userLink : HalLink
    }


type alias ApiPossibleAction =
    { playerLink : HalLink
    , position : ( Int, Int )
    }


type alias ApiPossibleActionList =
    { game : ApiGame
    , possibleActions : List ApiPossibleAction
    }


type alias ApiRoot =
    { gameLink : HalLink
    , gamesLink : HalLink
    , identitiesLink : HalLink
    , localAuthLink : HalLink
    , statsLink : HalLink
    , usersLink : HalLink
    }


type alias ApiStats =
    { actions : Int
    , games : ApiGameStats
    , identities : Int
    , nodes : Dict String ApiNodeStats
    , players : Int
    , users : Int
    }


type alias ApiUser =
    { createdAt : String
    , name : String
    , selfLink : HalLink
    }


type alias ApiUserWithToken =
    WithToken ApiUser


type alias HalLink =
    { href : String
    , templated : Bool
    }


type alias WithToken a =
    { a | token : String }


apiBoardDecoder : Decoder ApiBoard
apiBoardDecoder =
    Decode.succeed ApiBoard
        |> required "data" (list apiPieceDecoder)
        |> required "dimensions" apiPositionDecoder


apiGameDecoder : Decoder ApiGame
apiGameDecoder =
    Decode.succeed ApiGame
        |> required "_links" (field "boardr:actions" halLinkDecoder)
        |> required "_links" (field "boardr:board" halLinkDecoder)
        |> required "createdAt" string
        |> required "id" string
        |> required "_links" (field "boardr:players" halLinkDecoder)
        |> required "_links" (field "boardr:possible-actions" halLinkDecoder)
        |> required "rules" string
        |> required "_links" (field "self" halLinkDecoder)
        |> required "state" apiGameStateDecoder
        |> optional "title" (maybe string) Nothing
        |> optional "_embedded" (maybe (field "boardr:winners" (list apiPlayerDecoder))) Nothing


apiGameDetailedDecoder : Decoder ApiGameDetailed
apiGameDetailedDecoder =
    Decode.succeed ApiGameDetailed
        |> required "_links" (field "boardr:actions" halLinkDecoder)
        |> required "_links" (field "boardr:board" halLinkDecoder)
        |> required "createdAt" string
        |> required "id" string
        |> required "_embedded" (field "boardr:players" (list apiPlayerDecoder))
        |> required "_links" (field "boardr:players" halLinkDecoder)
        |> required "_links" (field "boardr:possible-actions" halLinkDecoder)
        |> required "rules" string
        |> required "_links" (field "self" halLinkDecoder)
        |> required "state" apiGameStateDecoder
        |> optional "title" (maybe string) Nothing
        |> optional "_embedded" (maybe (field "boardr:winners" (list apiPlayerDecoder))) Nothing


apiGameListDecoder : Decoder ApiGameList
apiGameListDecoder =
    Decode.succeed ApiGameList
        |> required "_embedded" (field "boardr:games" (list apiGameDecoder))
        |> required "_embedded" (field "boardr:players" (list apiPlayerDecoder))


apiGameStateDecoder : Decoder ApiGameState
apiGameStateDecoder =
    Decode.string
        |> Decode.andThen
            (\s ->
                case s of
                    "waiting_for_players" ->
                        Decode.succeed WaitingForPlayers

                    "playing" ->
                        Decode.succeed Playing

                    "draw" ->
                        Decode.succeed Draw

                    "win" ->
                        Decode.succeed Win

                    _ ->
                        Decode.fail ("Unknown game state " ++ s)
            )


apiGameStatsDecoder : Decoder ApiGameStats
apiGameStatsDecoder =
    Decode.succeed ApiGameStats
        |> required "draw" int
        |> required "inactive" (field "count" int)
        |> required "playing" int
        |> required "waiting_for_players" int
        |> required "win" int


apiGameWithoutDetails : ApiGameDetailed -> ApiGame
apiGameWithoutDetails apiGame =
    { actionsLink = apiGame.actionsLink
    , boardLink = apiGame.boardLink
    , createdAt = apiGame.createdAt
    , id = apiGame.id
    , playersLink = apiGame.playersLink
    , possibleActionsLink = apiGame.possibleActionsLink
    , rules = apiGame.rules
    , selfLink = apiGame.selfLink
    , state = apiGame.state
    , title = apiGame.title
    , winners = apiGame.winners
    }


apiIdentityDecoder : Decoder ApiIdentity
apiIdentityDecoder =
    Decode.succeed ApiIdentity
        |> required "createdAt" string
        |> required "email" string
        |> required "id" string
        |> required "_embedded" (field "boardr:token" (field "value" string))


apiLocalAuthenticationDecoder : Decoder ApiLocalAuthentication
apiLocalAuthenticationDecoder =
    Decode.succeed ApiLocalAuthentication
        |> required "_embedded" (field "boardr:token" (field "value" string))
        |> required "_embedded" (field "boardr:user" apiUserDecoder)


apiNodeStatsDecoder : Decoder ApiNodeStats
apiNodeStatsDecoder =
    Decode.succeed ApiNodeStats
        |> required "game_servers" int
        |> required "swarm_processes" int


apiPieceDecoder : Decoder ApiPiece
apiPieceDecoder =
    Decode.succeed ApiPiece
        |> required "player" int
        |> required "position" apiPositionDecoder


apiPlayerDecoder : Decoder ApiPlayer
apiPlayerDecoder =
    Decode.succeed ApiPlayer
        |> required "createdAt" string
        |> required "id" string
        |> required "number" int
        |> required "_links" (field "boardr:game" halLinkDecoder)
        |> required "_links" (field "self" halLinkDecoder)
        |> required "_links" (field "boardr:user" halLinkDecoder)


apiPositionDecoder : Decoder ( Int, Int )
apiPositionDecoder =
    Decode.map2 Tuple.pair
        (Decode.index 0 Decode.int)
        (Decode.index 1 Decode.int)


apiPossibleActionDecoder : Decoder ApiPossibleAction
apiPossibleActionDecoder =
    Decode.succeed ApiPossibleAction
        |> required "_links" (field "boardr:player" halLinkDecoder)
        |> required "position" apiPositionDecoder


apiPossibleActionListDecoder : Decoder ApiPossibleActionList
apiPossibleActionListDecoder =
    Decode.succeed ApiPossibleActionList
        |> required "_embedded" (field "boardr:game" apiGameDecoder)
        |> required "_embedded" (field "boardr:possible-actions" (list apiPossibleActionDecoder))


apiRootDecoder : Decoder ApiRoot
apiRootDecoder =
    Decode.succeed ApiRoot
        |> required "_links" (field "boardr:game" halLinkDecoder)
        |> required "_links" (field "boardr:games" halLinkDecoder)
        |> required "_links" (field "boardr:identities" halLinkDecoder)
        |> required "_links" (field "boardr:local-auth" halLinkDecoder)
        |> required "_links" (field "boardr:stats" halLinkDecoder)
        |> required "_links" (field "boardr:users" halLinkDecoder)


apiStatsDecoder : Decoder ApiStats
apiStatsDecoder =
    Decode.succeed ApiStats
        |> required "db" (field "actions" int)
        |> required "db" (field "games" apiGameStatsDecoder)
        |> required "db" (field "identities" int)
        |> required "nodes" (dict apiNodeStatsDecoder)
        |> required "db" (field "players" int)
        |> required "db" (field "users" int)


apiUserDecoder : Decoder ApiUser
apiUserDecoder =
    Decode.succeed ApiUser
        |> required "createdAt" string
        |> required "name" string
        |> required "_links" (field "self" halLinkDecoder)


apiUserEncoder : ApiUser -> Encode.Value
apiUserEncoder apiUser =
    Encode.object
        [ ( "createdAt", Encode.string apiUser.createdAt )
        , ( "name", Encode.string apiUser.name )
        , ( "_links"
          , Encode.object
                [ ( "self", halLinkEncoder apiUser.selfLink )
                ]
          )
        ]


apiUserWithoutToken : ApiUserWithToken -> ApiUser
apiUserWithoutToken user =
    { createdAt = user.createdAt, name = user.name, selfLink = user.selfLink }


apiUserWithToken : String -> String -> HalLink -> String -> ApiUserWithToken
apiUserWithToken createdAt name selfLink token =
    { createdAt = createdAt, name = name, selfLink = selfLink, token = token }


apiUserWithTokenDecoder : Decoder ApiUserWithToken
apiUserWithTokenDecoder =
    Decode.succeed apiUserWithToken
        |> required "createdAt" string
        |> required "name" string
        |> required "_links" (field "self" halLinkDecoder)
        |> required "_embedded" (field "boardr:token" (field "value" string))


halLinkDecoder : Decoder HalLink
halLinkDecoder =
    Decode.succeed HalLink
        |> required "href" string
        |> optional "templated" bool False


halLinkEncoder : HalLink -> Encode.Value
halLinkEncoder link =
    Encode.object
        [ ( "href", Encode.string link.href )
        , ( "templated", Encode.bool link.templated )
        ]
