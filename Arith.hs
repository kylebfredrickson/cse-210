module Arith
( ArithAST
, arithExpr
, varStr
, arithEval
, arithParse
, arithASTToStr
) where

import Data.Char ( isDigit, isAlpha, isAlphaNum )
import Data.Map ( Map, lookup , empty)
import Prelude hiding ( lookup )
import Text.ParserCombinators.ReadP
    ( (+++), char, many1, option, readP_to_S, satisfy, skipSpaces, ReadP )

import Gen ( parens, brackets )

data ArithAST = ArithExpr {op :: ArithOps, l :: ArithAST, r :: ArithAST}
              | Var {v :: String}
              | Arr { v :: String, i :: ArithAST}
              | Int {n :: Integer} deriving Show

data ArithOps = Add
              | Sub
              | Mul
              | Exp deriving Show

arithOps :: [(ArithOps, Char)]
arithOps = [
    (Add,'+'),
    (Sub,'-'),
    (Mul,'*'),
    (Exp,'^')
    ]

-- Eval --

arithEval :: ArithAST -> Map String Integer -> Integer
arithEval (Int n) _ = n
arithEval (Var v) state = variableLookup (lookup v state)
arithEval (Arr v i) state = variableLookup (lookup (v ++ show (arithEval i state)) state)
arithEval (ArithExpr Add l r)  state = arithEval l  state + arithEval r  state
arithEval (ArithExpr Sub l r)  state = arithEval l  state - arithEval r  state
arithEval (ArithExpr Mul l r)  state = arithEval l  state * arithEval r  state
arithEval (ArithExpr Exp l r)  state = arithEval l  state ^ arithEval r  state

variableLookup :: Maybe Integer -> Integer
variableLookup (Just n) = n
variableLookup Nothing = 0

-- Parse --

arithParse :: String -> ArithAST
arithParse s = let (fst, snd) = (last . readP_to_S arithExpr) s
    in if snd == "" then
        fst
    else
        Int 0

arithExpr :: ReadP ArithAST
arithExpr = foldr (\(op,name) p ->
    let this = p +++ do a <- p +++ parens arithExpr
                        char name
                        ArithExpr op a <$> this
            in this)
        (number +++ var +++ arr +++ parens arithExpr)
            arithOps

arr ::  ReadP ArithAST
arr = do
    skipSpaces
    v <- varStr
    skipSpaces
    i <- brackets arithExpr
    skipSpaces
    return (Arr v i)

var :: ReadP ArithAST
var = do Var <$> varStr

varStr :: ReadP String
varStr = do
    skipSpaces
    f <- satisfy isAlpha
    v <- option "" (many1 (satisfy isAlphaNum))
    skipSpaces
    return (f : v)

number :: ReadP ArithAST
number = do
    skipSpaces
    minus <- option '0' (char '-')
    digits <- many1 (satisfy isDigit)
    skipSpaces
    return (Int (read (minus : digits)))

-- Debugging Tools --

arithASTToStr :: ArithAST -> [Char]
arithASTToStr (Int n) = show n
arithASTToStr (Var v) = show v
arithASTToStr (Arr v i) = show v ++ "[" ++ arithASTToStr i ++ "]"
arithASTToStr (ArithExpr Add l r) = "(+ " ++ arithASTToStr l ++ " " ++ arithASTToStr r ++ ")"
arithASTToStr (ArithExpr Sub l r) = "(- " ++ arithASTToStr l ++ " " ++ arithASTToStr r ++ ")"
arithASTToStr (ArithExpr Mul l r) = "(* " ++ arithASTToStr l ++ " " ++ arithASTToStr r ++ ")"
arithASTToStr (ArithExpr Exp l r) = "(^ " ++ arithASTToStr l ++ " " ++ arithASTToStr r ++ ")"

-- main :: IO ()
-- main = do
--     expr <- getLine
--     (print . ( `arithEval` empty) . arithParse) expr