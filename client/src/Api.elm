module Api exposing (ApiGame, ApiGameList, ApiRoot, apiGameDecoder, apiGameListDecoder, apiRootDecoder)

import Json.Decode as Decode exposing (Decoder, bool, field, int, list, maybe, string)
import Json.Decode.Pipeline exposing (optional, required)


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
    , players : Maybe (List ApiPlayer) }


type alias ApiPlayer =
    { createdAt : String
    , number : Int
    , userLink : HalLink }


type alias ApiRoot =
    { gameLink : HalLink
    , gamesLink: HalLink
    }


type alias HalLink =
    { href : String
    , templated : Bool
    }


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


halLinkDecoder : Decoder HalLink
halLinkDecoder =
    Decode.succeed HalLink
        |> required "href" string
        |> optional "templated" bool False
