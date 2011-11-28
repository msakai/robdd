
> {-# OPTIONS_GHC -Wall #-}

> module Formula where

> import Data.Map (Map)
> import qualified Data.Map as M
> import NeList

We'll support labeled boolean variables, where (V 1) would correspond to 
the variable x1. We also support negation, conjunction, and disjunction.

> type Label = Int

> newtype Variable = V { label :: Label }
>   deriving Eq

> instance Show Variable where
>   show (V n) = 'x' : show n

> x1, x2, x3, x4 :: Variable
> x1 = V 1
> x2 = V 2
> x3 = V 3
> x4 = V 4

> data Formula = TM_T
>              | TM_F
>              | TM_Var Variable
>              | TM_Not Formula
>              | TM_Conj (List NonEmpty Formula)
>              | TM_Disj (List NonEmpty Formula)
>  deriving Eq

> instance Show Formula where
>   show TM_T = "T"
>   show TM_F = "F"
>   show (TM_Var v)  = show v
>   show (TM_Not f)  = '¬' : show f
>   show (TM_Conj fs) = '(' : showHelper " ∧ " ")" fs
>   show (TM_Disj fs)  = '(' : showHelper " ∨ " ")" fs

> f1, f2, f3, f4 :: Formula
> f1 = TM_Var x1
> f2 = TM_Not (TM_Var x2)
> f3 = TM_Conj (Cons (TM_Var x3) (Cons (TM_Var x4) Nil))
> f4 = TM_Disj (Cons f2 (Cons f3 Nil))

Next, given a formula an assignment over variables to boolan values, 
we determine if a formula is valid. An assignment is a mapping from
Labels to Booleans

> type Assignment = Map Label Bool

> valid :: Formula -> Assignment -> Bool
> valid f assign = case validWalker f assign of
>                    Just b -> b
>                    Nothing -> False
>                  where

Here, we use a helper function that produces a maybe bool. A nothing result
signifies that the assignment is incomplete, and subsequently insufficient
to determine the validity of the formula.

>   validWalker :: Formula -> Assignment -> Maybe Bool

Boolean values are trivial (and independent of the assignment!)

>   validWalker TM_T _ = return True
>   validWalker TM_F _ = return False

For variables, if a valuation is possible we produce the boolean, otherwise 
we indicate with a Nothing value that the validity cannot be determined.

>   validWalker (TM_Var (V x)) a = M.lookup x a

For negation, iff the valuation of the contained formuala can be determined, 
so can its negation.

>   validWalker (TM_Not f') a = fmap not $ validWalker f' a

Conjunction and disjunciton need helper functions (and haskell requires
these definitions to be grouped together, unlike top-level definitions)

>   validWalker (TM_Conj fs) a = validAll $ fmap (\f' -> validWalker f' a) fs
>   validWalker (TM_Disj fs)  a = validAny $ fmap (\f' -> validWalker f' a) fs

Conjunction requires that every recursive formula be valid. If any formula
cannot be determined (Nothing), the entire conjunction cannot be determined.
Otherwise, if any formula can be determined to be invalid, then the entire
conjunction is invalid, and otherwise the conjunction is valid

>   validAll :: List NonEmpty (Maybe Bool) -> Maybe Bool
>   validAll mxs = if neany (==Nothing) mxs
>                  then Nothing
>                  else if neany (==(Just False)) mxs
>                       then Just False
>                       else Just True                   

Disjunction only requires one formula to be valid. If any formula can be
determined to be valid, then the entire disjunction is valid. Otherwise, if
any formula cannot be determined (Nothing), then the entire disjunction
cannot be determined, and otherwise the disjunction is invalid.

>   validAny :: List NonEmpty (Maybe Bool) -> Maybe Bool
>   validAny mxs = if neany (==(Just True)) mxs
>                  then Just True
>                  else if neany (==(Nothing)) mxs
>                       then Nothing
>                       else Just False

Finally, some assignments that satisfy the formulas defined at the top
of the file

> a1, a1', a2, a2', a3 :: Assignment
> a1  = M.insert 1 True  M.empty
> a1' = M.insert 1 False M.empty
> a2  = M.insert 2 False M.empty
> a2' = M.insert 2 True  M.empty
> a3  = M.insert 3 True (M.insert 4 True M.empty)
