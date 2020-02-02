module Api.Model exposing
    ( ApiGame
    , ApiGameList
    , ApiGameState(..)
    , ApiIdentity
    , ApiLocalAuthentication
    , ApiPossibleActionList
    , ApiRoot
    , ApiUser
    , ApiUserWithToken
    , apiGameDecoder
    , apiGameListDecoder
    , apiIdentityDecoder
    , apiLocalAuthenticationDecoder
    , apiPossibleActionListDecoder
    , apiRootDecoder
    , apiUserDecoder
    , apiUserEncoder
    , apiUserWithTokenDecoder
    , apiUserWithoutToken
    )

import Json.Decode as Decode exposing (Decoder, bool, field, int, list, maybe, string)
import Json.Decode.Pipeline exposing (optional, required)
import Json.Encode as Encode


type alias ApiGame =
    { createdAt : String
    , id : String
    , possibleActionsLink : HalLink
    , rules : String
    , state : ApiGameState
    , title : Maybe String
    }


type ApiGameState
    = WaitingForPlayers
    | Playing
    | Draw
    | Win


type alias ApiGameList =
    { games : List ApiGame
    , players : Maybe (List ApiPlayer)
    }


type alias ApiIdentity =
    { createdAt : String
    , email : String
    , id : String
    , token : String
    }


type alias ApiLocalAuthentication =
    { token : String
    , user : ApiUser }


type alias ApiPlayer =
    { createdAt : String
    , number : Int
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
    , usersLink : HalLink
    }


type alias ApiUser =
    { createdAt : String
    , name : String
    }


type alias ApiUserWithToken =
    WithToken ApiUser


type alias HalLink =
    { href : String
    , templated : Bool
    }


type alias WithToken a =
    { a | token : String }


apiGameDecoder : Decoder ApiGame
apiGameDecoder =
    Decode.succeed ApiGame
        |> required "createdAt" string
        |> required "id" string
        |> required "_links" (field "boardr:possible-actions" halLinkDecoder)
        |> required "rules" string
        |> required "state" apiGameStateDecoder
        |> required "title" (maybe string)


apiGameListDecoder : Decoder ApiGameList
apiGameListDecoder =
    Decode.succeed ApiGameList
        |> required "_embedded" (field "boardr:games" (list apiGameDecoder))
        |> required "_embedded" (maybe (field "boardr:players" (list apiPlayerDecoder)))


apiGameStateDecoder : Decoder ApiGameState
apiGameStateDecoder =
    Decode.string |> Decode.andThen (\s ->
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


apiPlayerDecoder : Decoder ApiPlayer
apiPlayerDecoder =
    Decode.succeed ApiPlayer
        |> required "createdAt" string
        |> required "number" int
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
        |> required "_links" (field "boardr:users" halLinkDecoder)


apiUserDecoder : Decoder ApiUser
apiUserDecoder =
    Decode.succeed ApiUser
        |> required "createdAt" string
        |> required "name" string


apiUserEncoder : ApiUser -> Encode.Value
apiUserEncoder apiUser =
    Encode.object
        [ ( "createdAt", Encode.string apiUser.createdAt )
        , ( "name", Encode.string apiUser.name )
        ]


apiUserWithoutToken : ApiUserWithToken -> ApiUser
apiUserWithoutToken user =
    { createdAt = user.createdAt, name = user.name }


apiUserWithToken : String -> String -> String -> ApiUserWithToken
apiUserWithToken createdAt name token =
    { createdAt = createdAt, name = name, token = token }


apiUserWithTokenDecoder : Decoder ApiUserWithToken
apiUserWithTokenDecoder =
    Decode.succeed apiUserWithToken
        |> required "createdAt" string
        |> required "name" string
        |> required "_embedded" (field "boardr:token" (field "value" string))


halLinkDecoder : Decoder HalLink
halLinkDecoder =
    Decode.succeed HalLink
        |> required "href" string
        |> optional "templated" bool False
