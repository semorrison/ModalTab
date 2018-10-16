/-
Copyright (c) 2018 Minchao Wu. All rights reserved.
Released under MIT license as described in the file LICENSE.
Author: Minchao Wu
-/
import data.list

open nat tactic subtype

inductive nnf : Type
| var (n : nat)         
| neg (n : nat)         
| and (φ ψ : nnf)       
| or (φ ψ : nnf)        
| box (φ : nnf)
| dia (φ : nnf)

open nnf

def nnf.to_string : nnf → string
| (var n)    := "P" ++ n.repr
| (neg n)    := "¬P" ++ n.repr
| (and φ ψ)  := nnf.to_string φ ++ "∧" ++ nnf.to_string ψ
| (or φ ψ)   := nnf.to_string φ ++ "∨" ++ nnf.to_string ψ
| (box φ)    := "□" ++ nnf.to_string φ 
| (dia φ)    := "⋄" ++ nnf.to_string φ

instance nnf_repr : has_repr nnf := ⟨nnf.to_string⟩

instance dec_eq_nnf : decidable_eq nnf := by mk_dec_eq_instance

@[simp] def node_size : list nnf → ℕ 
| []          := 0
| (hd :: tl)  := sizeof hd + node_size tl

inductive close_instance (Γ : list nnf)
| cons : Π {n}, var n ∈ Γ → neg n ∈ Γ → close_instance

inductive and_instance (Γ : list nnf) : list nnf → Type
| cons : Π {φ ψ}, nnf.and φ ψ ∈ Γ → 
         and_instance (φ :: ψ :: Γ.erase (nnf.and φ ψ))

inductive or_instance (Γ : list nnf) : list nnf → list nnf → Type
| cons : Π {φ ψ}, nnf.or φ ψ ∈ Γ → 
         or_instance (φ :: Γ.erase (nnf.or φ ψ)) 
                     (ψ :: Γ.erase (nnf.or φ ψ))

def left_prcp : Π {Γ₁ Γ₂ Δ : list nnf} (i : or_instance Δ Γ₁ Γ₂), nnf 
| Γ₁ Γ₂ Δ (@or_instance.cons _ φ ψ _) := φ
