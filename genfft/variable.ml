(*
 * Copyright (c) 1997-1999 Massachusetts Institute of Technology
 * Copyright (c) 2000 Matteo Frigo
 * Copyright (c) 2000 Steven G. Johnson
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
 *
 *)
(* $Id: variable.ml,v 1.3 2002-06-20 22:51:33 athena Exp $ *)

type info =
  | Real of int
  | Imag of int 
  | Unknown

type variable = 
      (* temporary variables generated automatically *)
  | Temporary of int
      (* memory locations, e.g., array elements *)
  | Locative of (info * Unique.unique * Unique.unique * string)
      (* constant values, e.g., twiddle factors *)
  | Constant of (info * Unique.unique * string)

let hash v = Hashtbl.hash v

let same = (==)

let is_constant = function
  | Constant _ -> true
  | _ -> false

let is_temporary = function
  | Temporary _ -> true
  | _ -> false

let is_locative = function
  | Locative _ -> true
  | _ -> false

let info = function
  | Locative (i, _, _, _) -> i
  | Constant (i, _, _) -> i
  | _ -> failwith "info"

let same_location a b = 
  match (a, b) with
  | (Locative (_, location_a, _, _), Locative (_, location_b, _, _)) ->
      Unique.same location_a location_b
  | _ -> false

let same_class a b = 
  match (a, b) with
  | (Locative (_, _, class_a, _), Locative (_, _, class_b, _)) ->
      Unique.same class_a class_b
  | (Constant (_, class_a, _), Constant (_, class_b, _)) ->
      Unique.same class_a class_b
  | _ -> false

let make_temporary =
  let tmp_count = ref 0
  in fun () -> begin
    tmp_count := !tmp_count + 1;
    Temporary !tmp_count
  end

let make_constant info class_token name = 
  Constant (info, class_token, name)

let make_locative info location_token class_token name =
  Locative (info, location_token, class_token, name)

(* special naming conventions for variables *)
let rec base62_of_int k = 
  let x = k mod 62 
  and y = k / 62 in
  let c = 
    if x < 10 then 
      Char.chr (x + Char.code '0')
    else if x < 36 then
      Char.chr (x + Char.code 'a' - 10)
    else 
      Char.chr (x + Char.code 'A' - 36)
  in
  let s = String.make 1 c in
  let r = if y == 0 then "" else base62_of_int y in
  r ^ s

let varname_of_int k =
  if !Magic.compact then
    base62_of_int k
  else
    string_of_int k

let unparse = function
  | Temporary k -> "t" ^ (varname_of_int k)
  | Constant (_, _, name) -> name
  | Locative (_, _, _, name) -> name


let is_real v =
  match info v with
  | Real _ -> true
  | _ -> false

let is_imag v =
  match info v with
  | Imag _ -> true
  | _ -> false

let var_index v = 
  match info v with
  | Real x -> x
  | Imag x -> x
  | _ -> failwith "var_index"
