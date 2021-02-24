module Morphir.Visual.Components.AritmeticExpressions exposing (..)

import Morphir.IR.Name as Name exposing (Name)
import Morphir.IR.Path as Path exposing (Path)
import Morphir.IR.Type as Type
import Morphir.IR.Value as Value exposing (TypedValue, Value(..))


type ArithmeticOperatorTree
    = ArithmeticOperatorBranch ArithmeticOperator (List ArithmeticOperatorTree)
    | ArithmeticValueLeaf TypedValue
    | ArithmeticDivisionBranch (List ArithmeticOperatorTree)


type ArithmeticOperator
    = Add
    | Subtract
    | Multiply


fromArithmeticTypedValue : TypedValue -> ArithmeticOperatorTree
fromArithmeticTypedValue typedValue =
    case typedValue of
        Value.Apply _ fun arg ->
            let
                ( function, args ) =
                    Value.uncurryApply fun arg
            in
            case ( function, args ) of
                ( Value.Reference _ ( _, moduleName, localName ), [ arg1, arg2 ] ) ->
                    let
                        operatorName : String
                        operatorName =
                            functionName moduleName localName
                    in
                    case operatorName of
                        "Basics.add" ->
                            ArithmeticOperatorBranch Add (helperArithmeticTreeBuilderRecursion arg1 operatorName ++ helperArithmeticTreeBuilderRecursion arg2 operatorName)

                        "Basics.subtract" ->
                            ArithmeticOperatorBranch Subtract (helperArithmeticTreeBuilderRecursion arg1 operatorName ++ helperArithmeticTreeBuilderRecursion arg2 operatorName)

                        "Basics.divide" ->
                            ArithmeticDivisionBranch ([ ArithmeticValueLeaf arg1 ] ++ helperArithmeticTreeBuilderRecursion arg2 operatorName)

                        "Basics.multiply" ->
                            ArithmeticOperatorBranch Multiply (helperArithmeticTreeBuilderRecursion arg1 operatorName ++ helperArithmeticTreeBuilderRecursion arg2 operatorName)

                        _ ->
                            fromArithmeticTypedValue typedValue

                _ ->
                    fromArithmeticTypedValue typedValue

        _ ->
            ArithmeticValueLeaf typedValue


helperArithmeticTreeBuilderRecursion : TypedValue -> String -> List ArithmeticOperatorTree
helperArithmeticTreeBuilderRecursion value operatorName =
    case value of
        Value.Apply _ fun arg ->
            let
                ( function, args ) =
                    Value.uncurryApply fun arg
            in
            case ( function, args ) of
                ( Value.Reference _ ( _, moduleName, localName ), [ arg1, arg2 ] ) ->
                    case functionName moduleName localName of
                        "Basics.add" ->
                            [ ArithmeticOperatorBranch Add (helperArithmeticTreeBuilderRecursion arg1 operatorName ++ helperArithmeticTreeBuilderRecursion arg2 operatorName) ]

                        "Basics.subtract" ->
                            [ ArithmeticOperatorBranch Subtract (helperArithmeticTreeBuilderRecursion arg1 operatorName ++ helperArithmeticTreeBuilderRecursion arg2 operatorName) ]

                        "Basics.multiply" ->
                            [ ArithmeticOperatorBranch Multiply (helperArithmeticTreeBuilderRecursion arg1 operatorName ++ helperArithmeticTreeBuilderRecursion arg2 operatorName) ]

                        "Basics.divide" ->
                            [ ArithmeticDivisionBranch ([ ArithmeticValueLeaf arg1 ] ++ helperArithmeticTreeBuilderRecursion arg2 operatorName) ]

                        "Basics.float" ->
                            []

                        _ ->
                            helperArithmeticTreeBuilderRecursion value operatorName

                _ ->
                    helperArithmeticTreeBuilderRecursion value operatorName

        _ ->
            [ ArithmeticValueLeaf value ]


functionName : Path -> Name -> String
functionName moduleName localName =
    String.join "."
        [ moduleName |> Path.toString Name.toTitleCase "."
        , localName |> Name.toCamelCase
        ]


currentPrecedence : String -> Int
currentPrecedence operatorName =
    case operatorName of
        "Basics.add" ->
            1

        "Basics.subtract" ->
            1

        "Basics.multiply" ->
            2

        "Basics.divide" ->
            2

        _ ->
            0
