import .size
open nnf list

namespace list
universes u v w

variables {α : Type u} {β : Type v} {γ : Type w}

-- fancy!
@[simp] def smap (p : β → Prop) (f : α → β) : Π l : list α, (∀ a∈l, p (f a)) → 
{x : list β // (∀ e ∈ x, p e) ∧ ∀ i ∈ l, f i ∈ x}
| []         h := ⟨[], ⟨λ e h, by simpa using h, λ e h, by simpa using h⟩⟩
| (hd :: tl) h := ⟨f hd :: smap tl (λ a ha, h a $ mem_cons_of_mem _ ha), 
begin
  constructor,
  { intros e he, cases he, 
    {rw he, apply h, simp}, 
    {apply (smap tl _).2.1, exact he} },
  { intros e he, cases he, 
    {rw he, simp},
    {apply mem_cons_of_mem, apply (smap tl _).2.2, exact he} }
end⟩

@[simp] def ne_empty_head : Π l : list α, l ≠ [] → α
| []       h := by contradiction
| (a :: l) h := a

end list

@[simp] def unbox : list nnf → list nnf
| [] := []
| ((box φ) :: l) := φ :: unbox l
| (e :: l) := unbox l

theorem unbox_iff : Π {Γ φ}, box φ ∈ Γ ↔ φ ∈ unbox Γ
| [] φ := begin split, repeat {intro h, simpa using h} end
| (hd::tl) φ := 
begin
  split,
  { intro h, cases h₁ : hd, 
    case nnf.box : ψ 
    { dsimp [unbox], cases h, 
       {left, rw h₁ at h, injection h},
       {right, exact (@unbox_iff tl φ).1 h} },
    all_goals 
    { dsimp [unbox], cases h, 
       {rw h₁ at h, contradiction},
       {exact (@unbox_iff tl φ).1 h} } },
  { intro h, cases h₁ : hd, 
    case nnf.box : ψ
    { rw h₁ at h, dsimp [unbox] at h, cases h, 
       {simp [h]}, {right, exact (@unbox_iff tl φ).2 h} },
    all_goals 
    { rw h₁ at h, dsimp [unbox] at h, right, exact (@unbox_iff tl φ).2 h } }
end

theorem unbox_size_aux : Π {Γ}, node_size (unbox Γ) ≤ node_size Γ
| [] := by simp
| (hd::tl) := 
begin
  cases h : hd,
  case nnf.box : ψ
  { dsimp, apply add_le_add, 
     { dsimp [sizeof, has_sizeof.sizeof, nnf.sizeof], 
       rw add_comm, apply nat.le_succ }, 
     { apply unbox_size_aux } },
  all_goals 
  { dsimp, apply le_add_of_nonneg_of_le, 
    { dsimp [sizeof, has_sizeof.sizeof, nnf.sizeof], rw add_comm, apply nat.zero_le }, 
    { apply unbox_size_aux } }
end

theorem unbox_size : Π {Γ φ}, dia φ ∈ Γ → 
                     node_size (unbox Γ) + sizeof φ < node_size Γ
| [] := by simp
| (hd::tl) := 
begin
  intros φ h,
  cases h₁ : hd,
  case nnf.box : ψ
  {dsimp, cases h,
    {rw h₁ at h, contradiction},
    {rw add_assoc, apply add_lt_add, 
      {dsimp [sizeof, has_sizeof.sizeof, nnf.sizeof], rw add_comm, apply nat.lt_succ_self}, 
      {apply unbox_size, exact h} } },
  case nnf.dia : ψ
  {dsimp, rw add_comm, cases h, 
    {rw h₁ at h, have : φ = ψ, injection h, rw this, 
     apply add_lt_add_of_lt_of_le,
     {dsimp [sizeof, has_sizeof.sizeof, nnf.sizeof], rw add_comm, apply nat.lt_succ_self}, 
     {apply unbox_size_aux} },
    {apply lt_add_of_pos_of_lt, 
     {dsimp [sizeof, has_sizeof.sizeof, nnf.sizeof], rw add_comm, apply nat.succ_pos}, 
     {rw add_comm, apply unbox_size, exact h} } },
  all_goals 
  {dsimp, apply nat.lt_add_left, apply unbox_size, 
  cases h, rw h₁ at h, contradiction, exact h}
end

@[simp] def rebox : list nnf → list nnf 
| [] := []
| (hd::tl) := box hd :: rebox tl

theorem rebox_unbox_of_mem : Π {Γ} (h : ∀ {φ}, φ ∈ unbox Γ → box φ ∈ Γ), rebox (unbox Γ) ⊆ Γ
| [] h := by simp
| (hd::tl) h := 
begin
  cases hψ : hd,
  case nnf.box : φ {dsimp, simp [cons_subset_cons], apply subset_cons_of_subset, apply rebox_unbox_of_mem, simp [unbox_iff]},
  all_goals {dsimp, apply subset_cons_of_subset, apply rebox_unbox_of_mem, simp [unbox_iff]}
end

theorem unbox_rebox : Π {Γ}, unbox (rebox Γ) = Γ
| [] := by simp
| (hd::tl) := by simp [unbox_rebox]

-- Just that I don't want to say ∃ φ s.t. ...
def box_only_rebox : Π {Γ}, box_only (rebox Γ)
| [] := {no_var := by simp, 
         no_neg := by simp, 
         no_and := by simp, 
         no_or := by simp, 
         no_dia := by simp}
| (hd::tl) := 
begin
  cases h : hd,
  all_goals {
  exact { no_var := begin 
                      intros n h, cases h, contradiction, 
                      apply (@box_only_rebox tl).no_var, assumption 
                    end, 
          no_neg := begin 
                      intros n h, cases h, contradiction, 
                      apply (@box_only_rebox tl).no_neg, assumption 
                    end,
          no_and := begin 
                      intros φ ψ h, cases h, contradiction, 
                      apply (@box_only_rebox tl).no_and, assumption 
                    end,
          no_or := begin 
                     intros φ ψ h, cases h, contradiction, 
                     apply (@box_only_rebox tl).no_or, assumption 
                   end, 
          no_dia := begin 
                      intros φ h, cases h, contradiction, 
                      apply (@box_only_rebox tl).no_dia, assumption 
                    end} }
end

theorem mem_rebox : Π {φ Γ}, box φ ∈ rebox Γ ↔ φ ∈ Γ
| φ [] := by simp
| φ (hd::tl) := 
begin
  split, 
  {intro h, cases h₁ : hd, 
   all_goals { cases h, 
               {left, rw ←h₁, injection h}, 
               {right,  have := (@mem_rebox φ tl).1, exact this h } }},
  {intro h, cases h₁ : hd, 
   all_goals { dsimp, cases h, 
               {left, rw ←h₁, rw h}, 
               {right, have := (@mem_rebox φ tl).2, exact this h } } }
end

@[simp] def undia : list nnf → list nnf
| [] := []
| ((dia φ) :: l) := φ :: undia l
| (e :: l) := undia l

theorem undia_iff : Π {Γ φ}, dia φ ∈ Γ ↔ φ ∈ undia Γ
| [] φ := begin split, repeat {intro h, simpa using h} end
| (hd::tl) φ := 
begin
  split,
  { intro h, cases h₁ : hd, 
    case nnf.dia : ψ 
    { dsimp [undia], cases h, 
       {left, rw h₁ at h, injection h},
       {right, exact (@undia_iff tl φ).1 h} },
    all_goals 
    { dsimp [undia], cases h, 
       {rw h₁ at h, contradiction},
       {exact (@undia_iff tl φ).1 h} } },
  { intro h, cases h₁ : hd, 
    case nnf.dia : ψ
    { rw h₁ at h, dsimp [undia] at h, cases h, 
       {simp [h]}, {right, exact (@undia_iff tl φ).2 h} },
    all_goals 
    { rw h₁ at h, dsimp [undia] at h, right, exact (@undia_iff tl φ).2 h } }
end

theorem undia_size : Π {Γ φ}, φ ∈ undia Γ → 
                     sizeof φ + node_size (unbox Γ) < node_size Γ
:= 
begin
  intros Γ φ h,
  rw add_comm,
  apply unbox_size,
  rw undia_iff, exact h
end

@[simp] def get_modal : list nnf → list nnf
| [] := []
| (φ@(dia ψ) :: l) := φ :: get_modal l
| (φ@(box ψ) :: l) := φ :: get_modal l
| (e :: l) := get_modal l

theorem get_modal_iff_dia : Π {Γ} {φ : nnf},
dia φ ∈ get_modal Γ ↔ dia φ ∈ Γ
| [] φ := by simp
| (hd::tl) φ := 
begin
  split, 
  {intro h, cases heq : hd, 
   case nnf.dia : ψ 
   {rw heq at h, dsimp at h, cases h, left, exact h, right, 
    have := (@get_modal_iff_dia tl φ), have := this.1 h, exact this},
   case nnf.box : ψ 
   {rw heq at h, dsimp at h, cases h, contradiction, right, 
    have := (@get_modal_iff_dia tl φ), have := this.1 h, exact this},
   all_goals 
   {rw heq at h, dsimp at h, right, 
    have := (@get_modal_iff_dia tl φ), have := this.1 h, exact this}},
  {intro h, cases heq : hd, 
   case nnf.dia : ψ 
   {dsimp, rw heq at h, cases h, left, exact h, right, 
    have := (@get_modal_iff_dia tl φ), have := this.2 h, exact this},
   case nnf.box : ψ
   {dsimp, rw heq at h, cases h, contradiction, right, 
    have := (@get_modal_iff_dia tl φ), have := this.2 h, exact this},
   all_goals 
   {dsimp, rw heq at h, cases h, contradiction,  
    have := (@get_modal_iff_dia tl φ), have := this.2 h, exact this}
  }
end

theorem get_modal_iff_box : Π {Γ} {φ : nnf},
box φ ∈ get_modal Γ ↔ box φ ∈ Γ
| [] φ := by simp
| (hd::tl) φ := 
begin
  split, 
  {intro h, cases heq : hd, 
   case nnf.box : ψ 
   {rw heq at h, dsimp at h, cases h, left, exact h, right, 
    have := (@get_modal_iff_box tl φ), have := this.1 h, exact this},
   case nnf.dia : ψ 
   {rw heq at h, dsimp at h, cases h, contradiction, right, 
    have := (@get_modal_iff_box tl φ), have := this.1 h, exact this},
   all_goals 
   {rw heq at h, dsimp at h, right, 
    have := (@get_modal_iff_box tl φ), have := this.1 h, exact this}},
  {intro h, cases heq : hd, 
   case nnf.box : ψ 
   {dsimp, rw heq at h, cases h, left, exact h, right, 
    have := (@get_modal_iff_box tl φ), have := this.2 h, exact this},
   case nnf.dia : ψ
   {dsimp, rw heq at h, cases h, contradiction, right, 
    have := (@get_modal_iff_box tl φ), have := this.2 h, exact this},
   all_goals 
   {dsimp, rw heq at h, cases h, contradiction,  
    have := (@get_modal_iff_box tl φ), have := this.2 h, exact this}}
end

def get_contra : Π Γ : list nnf, 
                 psum {p : nat // var p ∈ Γ ∧ neg p ∈ Γ} 
                      (∀ n, var n ∈ Γ → neg n ∉ Γ)
| []             := psum.inr $ λ _ h, absurd h $ not_mem_nil _
| (hd :: tl)     := 
begin
  cases h : hd,
  case nnf.var : n 
  {apply dite (neg n ∈ tl),
    {intro t, 
     exact psum.inl ⟨n, ⟨mem_cons_self _ _, mem_cons_of_mem _ t⟩⟩},
    {intro e, 
     cases (get_contra tl),
     {left, constructor, constructor,
     apply mem_cons_of_mem, exact val.2.1,
     apply mem_cons_of_mem, exact val.2.2},
     {right,
      intros m hm hin, 
      by_cases eq : m=n,
      {apply e, cases hin, contradiction, rw ←eq, assumption},
      {cases hm, apply eq, injection hm, apply val, exact hm, 
       cases hin, contradiction, assumption} } }
  },
  case nnf.neg : n 
  { apply dite (var n ∈ tl),
    { intro t, 
      exact psum.inl ⟨n, ⟨mem_cons_of_mem _ t, mem_cons_self _ _⟩⟩ },
    { intro e, 
      cases (get_contra tl),
      {left, constructor, constructor,
      apply mem_cons_of_mem, exact val.2.1,
      apply mem_cons_of_mem, exact val.2.2 },
      { right,
        intros m hm hin, 
        by_cases eq : m=n,
        { apply e, cases hm, contradiction, rw ←eq, assumption },
        { cases hin, apply eq, injection hin, apply val, 
          swap, exact hin, cases hm, contradiction, assumption } 
      } 
    }
  },
  all_goals
  { 
  cases (get_contra tl),
  { left, constructor, constructor,
    apply mem_cons_of_mem, exact val.2.1,
    apply mem_cons_of_mem, exact val.2.2  },
  { right,
    intros m hm hin, 
    {apply val, swap 3, exact m, 
    cases hm, contradiction, assumption,
    cases hin, contradiction, assumption} }
  }
end

def get_and : Π Γ : list nnf, 
              psum {p : nnf × nnf // and p.1 p.2 ∈ Γ} 
                   (∀ φ ψ, nnf.and φ ψ ∉ Γ)
| []               := psum.inr $ λ _ _, not_mem_nil _
| (hd :: tl)       := 
begin
  cases h : hd,
  case nnf.and : φ ψ { left, constructor,swap,
                       constructor, exact φ, exact ψ, simp
                     },
  all_goals 
  { cases (get_and tl),
    {left,
    constructor,
    apply mem_cons_of_mem,
    exact val.2},
    {right, intros γ ψ h, 
     cases h, contradiction,
    apply val, assumption }
  }
end

def get_or : Π Γ : list nnf, 
              psum {p : nnf × nnf // or p.1 p.2 ∈ Γ} 
                   (∀ φ ψ, nnf.or φ ψ ∉ Γ)
| []               := psum.inr $ λ _ _, not_mem_nil _
| (hd :: tl)       :=
begin
  cases h : hd,
  case nnf.or : φ ψ { left, constructor,swap,
                       constructor, exact φ, exact ψ, simp },
  all_goals 
  { cases (get_or tl),
    {left,
    constructor,
    apply mem_cons_of_mem,
    exact val.2},
    {right, intros γ ψ h, 
     cases h, contradiction,
    apply val, assumption}
  }
end

def get_dia : Π Γ : list nnf, 
              psum {p : nnf // dia p ∈ Γ} 
                   (∀ φ, nnf.dia φ ∉ Γ)
| []               := psum.inr $ λ _, not_mem_nil _
| (hd :: tl)       := 
begin
  cases h : hd,
  case nnf.dia : φ { left, constructor, swap, exact φ, simp },
  all_goals 
  { cases (get_dia tl),
    {left,
    constructor,
    apply mem_cons_of_mem,
    exact val.2},
    {right, intros γ h, 
     cases h, contradiction,
     apply val, assumption } }
end

@[simp] def get_var : list nnf → list ℕ
| [] := []
| ((var n) :: l) := n :: get_var l
| (e :: l) := get_var l

theorem get_var_iff : Π {Γ n}, var n ∈ Γ ↔ n ∈ get_var Γ
| [] φ := begin split, repeat {intro h, simpa using h} end
| (hd::tl) φ := 
begin
  split,
  { intro h, cases h₁ : hd, 
    case nnf.var : n
    { dsimp, cases h, 
       {left, rw h₁ at h, injection h},
       {right, exact (@get_var_iff tl φ).1 h} },
    all_goals 
    { dsimp, cases h, 
       {rw h₁ at h, contradiction},
       {exact (@get_var_iff tl φ).1 h} } },
  { intro h, cases h₁ : hd, 
    case nnf.var : n
    { rw h₁ at h, dsimp at h, cases h, 
       {simp [h]}, {right, exact (@get_var_iff tl φ).2 h} },
    all_goals 
    { rw h₁ at h, dsimp [undia] at h, right, exact (@get_var_iff tl φ).2 h } }
end
