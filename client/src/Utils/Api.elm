module Utils.Api exposing (ApiGame, ApiGameList, apiGameListDecoder)

import Json.Decode as Decode exposing (Decoder, list, maybe, string)
import Json.Decode.Pipeline exposing (hardcoded, optional, required)


type alias ApiGame =
    { links : ApiGameLinks
    , createdAt : String
    , rules : String
    , title : Maybe String
    }


type alias ApiGameLinks =
    { self : HalLink }


type alias ApiGameListEmbedded =
    { games : List ApiGame }


type alias HalLink =
    { href : String }


type alias ApiGameList =
    { embedded : ApiGameListEmbedded }


apiGameListEmbeddedDecoder : Decoder ApiGameListEmbedded
apiGameListEmbeddedDecoder =
    Decode.succeed ApiGameListEmbedded
        |> required "boardr:games" (list apiGameDecoder)


apiGameListDecoder : Decoder ApiGameList
apiGameListDecoder =
    Decode.succeed ApiGameList
        |> required "_embedded" apiGameListEmbeddedDecoder


apiGameDecoder : Decoder ApiGame
apiGameDecoder =
    Decode.succeed ApiGame
        |> required "_links" apiGameLinksDecoder
        |> required "createdAt" string
        |> required "rules" string
        |> required "title" (maybe string)


apiGameLinksDecoder : Decoder ApiGameLinks
apiGameLinksDecoder =
    Decode.succeed ApiGameLinks
        |> required "self" halLinkDecoder


halLinkDecoder : Decoder HalLink
halLinkDecoder =
    Decode.succeed HalLink
        |> required "href" string