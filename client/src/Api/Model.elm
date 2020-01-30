module Api.Model exposing
    ( ApiGame
    , ApiGameList
    , ApiIdentity
    , ApiLocalAuthentication
    , ApiRoot
    , ApiUser
    , ApiUserWithToken
    , apiGameDecoder
    , apiGameListDecoder
    , apiIdentityDecoder
    , apiLocalAuthenticationDecoder
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
    { links : ApiGameLinks
    , createdAt : String
    , id : String
    , rules : String
    , title : Maybe String
    }


type alias ApiGameLinks =
    { collection : HalLink
    , self : HalLink
    }


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


apiGameListDecoder : Decoder ApiGameList
apiGameListDecoder =
    Decode.succeed ApiGameList
        |> required "_embedded" (field "boardr:games" (list apiGameDecoder))
        |> required "_embedded" (maybe (field "boardr:players" (list apiPlayerDecoder)))


apiGameDecoder : Decoder ApiGame
apiGameDecoder =
    Decode.succeed ApiGame
        |> required "_links" apiGameLinksDecoder
        |> required "createdAt" string
        |> required "id" string
        |> required "rules" string
        |> required "title" (maybe string)


apiGameLinksDecoder : Decoder ApiGameLinks
apiGameLinksDecoder =
    Decode.succeed ApiGameLinks
        |> required "collection" halLinkDecoder
        |> required "self" halLinkDecoder


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
