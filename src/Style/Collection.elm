module Style.Collection exposing (apply, map2, map3, bake)

import Style.PropertyHelpers exposing (id, Style, Dynamic, Physics, Retarget, DynamicColor(..))
import Color


map2 : (Float -> Physics -> Physics) -> Style -> List Dynamic -> List Dynamic
map2 fn style dyn =
    let
        matched =
            zipWith (\a b -> id a == id b) dyn style

        colorFn prevColor currentDColor =
            let
                { red, blue, green, alpha } =
                    Color.toRgb prevColor
            in
                case currentDColor of
                    RGBA r2 g2 b2 a2 ->
                        RGBA (fn (toFloat red) r2) (fn (toFloat green) g2) (fn (toFloat blue) b2) (fn alpha a2)
    in
        List.filterMap
            (\( dynamic, mTarget ) ->
                Maybe.map (\target -> Style.PropertyHelpers.map2 fn colorFn target dynamic) mTarget
            )
            matched



-- updateFrom : (Physics -> Physics -> Physics) -> Dynamic -> Dynamic -> Dynamic
-- updateFrom fn prev prop =
--     map2
--         fn
--         (\prevDColor currentDColor ->
--             case prevDColor of
--                 RGBA r1 g1 b1 a1 ->
--                     case currentDColor of
--                         RGBA r2 g2 b2 a2 ->
--                             RGBA (fn r1 r2) (fn g1 g2) (fn b1 b2) (fn a1 a2)
--         )
--         prev
--         prop


apply : List Retarget -> Style -> Style
apply retarget style =
    let
        matched =
            zipWith (\a b -> id a == id b) retarget style
    in
        List.filterMap
            (\( retarg, mSty ) ->
                Maybe.map (Style.PropertyHelpers.apply retarg) mSty
            )
            matched


map3 : (Float -> Float -> Physics -> Physics) -> Style -> Style -> List Dynamic -> List Dynamic
map3 fn prev target current =
    let
        matched =
            zipWith3 (\a b -> id a == id b) current prev target
    in
        List.map
            (\( curr, mB, mC ) ->
                case mB of
                    Nothing ->
                        curr

                    Just b ->
                        case mC of
                            Nothing ->
                                curr

                            Just c ->
                                Style.PropertyHelpers.updateOver fn b c curr
            )
            matched


zipWith3 : (a -> b -> Bool) -> List a -> List b -> List b -> List ( a, Maybe b, Maybe b )
zipWith3 fn listA listB listC =
    let
        ( results, _, _ ) =
            List.foldl
                (\a ( stack, bStack, cStack ) ->
                    let
                        ( matchingB, unmatchingB ) =
                            List.partition (\b -> fn a b) bStack

                        remainingB =
                            Maybe.withDefault [] <| List.tail matchingB

                        ( matchingC, unmatchingC ) =
                            List.partition (\c -> fn a c) cStack

                        remainingC =
                            Maybe.withDefault [] <| List.tail matchingC
                    in
                        ( stack ++ [ ( a, List.head matchingB, List.head matchingC ) ]
                        , unmatchingB ++ remainingB
                        , unmatchingC ++ remainingC
                        )
                )
                ( [], listB, listC )
                listA
    in
        results


zipWith : (a -> b -> Bool) -> List a -> List b -> List ( a, Maybe b )
zipWith fn listA listB =
    fst <|
        List.foldl
            (\a ( stack, bStack ) ->
                let
                    ( matching, unmatching ) =
                        List.partition (\b -> fn a b) bStack

                    maybeB =
                        List.head matching

                    remaining =
                        Maybe.withDefault [] <| List.tail matching
                in
                    ( stack ++ [ ( a, maybeB ) ], unmatching ++ remaining )
            )
            ( [], listB )
            listA


fill : Style -> Style -> Style
fill existing new =
    zipWith (\a b -> Style.PropertyHelpers.id a == Style.PropertyHelpers.id b) existing new
        |> List.map (\( a, maybeB ) -> Maybe.withDefault a maybeB)


bake : List Dynamic -> Style -> Style
bake dynamic style =
    fill style <|
        List.map
            Style.PropertyHelpers.toStatic
            dynamic


mapTo : Int -> (a -> a) -> List a -> List a
mapTo i fn xs =
    let
        update j x =
            if j == i then
                fn x
            else
                x
    in
        List.indexedMap update xs



--
-- getPropCount x list =
--     List.foldl
--         (\y acc ->
--             if Style.PropertyHelpers.id x == Style.PropertyHelpers.id y then
--                 acc + 1
--             else
--                 acc
--         )
--         1
--         list
--
--
-- mapWithCount fn list =
--     let
--         mapped =
--             List.foldl
--                 (\x acc ->
--                     let
--                         count =
--                             getPropCount (snd x) acc.past
--                     in
--                         { current = acc.current ++ [ fn count x ]
--                         , past = acc.past ++ [ snd x ]
--                         }
--                 )
--                 { current = []
--                 , past = []
--                 }
--                 list
--     in
--         mapped.current
--
--
-- matchPoints : Keyframe -> Style -> Keyframe
-- matchPoints frame lastTargetStyle =
--     let
--         paired =
--             zipWith (\a b -> Style.PropertyHelpers.id a.target == Style.PropertyHelpers.id b) frame.properties lastTargetStyle
--     in
--         { frame
--             | properties =
--                 List.map
--                     (\( frameProps, maybeLastTarget ) ->
--                         case maybeLastTarget of
--                             Nothing ->
--                                 frameProps
--
--                             Just lastTarget ->
--                                 { frameProps
--                                     | target = Style.PropertyHelpers.matchPoints frameProps.target lastTarget
--                                     , current = Style.PropertyHelpers.matchPoints frameProps.current lastTarget
--                                 }
--                     )
--                     paired
--         }
--
--