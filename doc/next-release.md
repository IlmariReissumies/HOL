% Release notes for HOL4, ??????

<!-- search and replace ?????? strings corresponding to release name -->
<!-- indent code within bulleted lists to column 11 -->

(Released: ??????)

We are pleased to announce the ?????? release of HOL 4.

Contents
--------

-   [New features](#new-features)
-   [Bugs fixed](#bugs-fixed)
-   [New theories](#new-theories)
-   [New tools](#new-tools)
-   [Examples](#examples)
-   [Incompatibilities](#incompatibilities)

New features:
-------------

*   `Holmake` under Poly/ML (*i.e.*, for the moment only Unix systems (including OSX/MacOS)) now runs build scripts concurrently when targets do not depend on each other.
    The degree of parallelisation depends on the `-j` flag, and is set to 4 by default.
    Output from the build processes is logged into a `.hollogs` sub-directory rather than interleaved randomly to standard out.

Bugs fixed:
-----------

New theories:
-------------

New tools:
----------

New examples:
---------

Incompatibilities:
------------------

*   The type of the “system printer” used by user-defined pretty-printers to pass control back to the default printer has changed.
    This function now gets passed an additional parameter corresponding to whether or not the default printer should treat the term to be printed as if it were in a binding position or not.
    (This `binderp` parameter is in addition to the parameters indicating the “depth” of the printing, and the precedence gravities.)
    See the *Reference* manual for more details.

*   The `PAT_ASSUM` tactics (`Tactical.PAT_ASSUM`, `Q.PAT_ASSUM` and `bossLib.qpat_assum`) have all been renamed to pick up an internal `_X_` (or `_x_`).
    Thus, the first becomes `PAT_X_ASSUM`, and the last becomes `qpat_x_assum`).
    This makes the names consistent with other theorem-tactics (*e.g.*, `first_x_assum`): the `X` (or `x`) indicates that the matching assumption is removed from the assumption list.
    Using the old names, we also now have versions that *don’t* remove the theorems from the assumption list.

    The behaviour of the quoting versions of the tactics is also slightly different: they will always respect names that occur both in the pattern and in the goal.
    Again, this is for consistency with similar functions such as `qspec_then`.
    This means, for example, that ``qpat_assum `a < b` `` will fail if the actual theorem being matched is something `c < f a`.
    (This is because the pattern and the goal share the name `a`, so that the pattern is implicitly requiring the first argument to `<` to be exactly `a`, which is not the case.)
    This example would have previously worked if there was exactly one assumption with `<`.
    The fix in cases like this is to use more underscores in one’s patterns.

*   The functions `Parse.Unicode.uoverload_on` and `Parse.Unicode.uset_fixity` have been removed because their functionality should be accessed *via* the standard `overload_on` and `set_fixity` functions.
    The “temporary” versions of these functions (*e.g.*, `Parse.Unicode.temp_uoverload_on`) have also been removed, analogously.
    The `Parse.Unicode.unicode_version` function remains, as does its temporary counterpart.

*   The simpset fragment `MOD_ss` has been added to the standard stateful simpset.
    This fragment does smart things with terms involving (natural number) `MOD`, allowing, for example, something like `((7 + y) * 100 + 5 * (z MOD 6)) MOD 6` to simplify to `((1 + y) * 4 + 5 * z) MOD 6`.
    If this breaks existing proofs in a script file, the fragment can be removed (for the rest of the execution of the script) with the command

           val _ = diminish_srw_ss ["MOD_ss"]

*   The rewrites `listTheory.TAKE_def` and `listTheory.DROP_def` have been removed from the standard stateful simpset.
    These rewrites introduce conditional expressions that are often painful to work with.
    Other more specific rewrites have been added to the simpset in their place.
    If the old behaviour is desired in a script file, the following will restore it

           val _ = augment_srw_ss
                    [rewrites [listTheory.DROP_def, listTheory.TAKE_def]]

*   The command-line options to the `build` tool have changed in some of their details.
    The standard usage by most users, which is to simply type `build` with no options at all, behaves as it did previously.
    For details on the options that are now handled, see the output of `build -h`.

*   The associativity and precedence level of the finite-map composition operators (of which there are three: `f_o_f`, `f_o` and `o_f`) have been changed to match that of normal function composition (infix `o`, or `∘`), which is a right-associative infix at precedence level 800.
    This level is tighter than exponentiation, multiplication and addition.
    This also matches the syntactic details for relation composition (which is written `O`, or `∘ᵣ`).
    If this causes problems within a script file, the old behaviour can be restored with, for example:

           val _ = set_fixity "o_f" (Infixl 500)

    This call will change the grammar used in all descendant theories as well; if the change is wanted only for the current script, use `temp_set_fixity` instead.

* * * * *

<div class="footer">
*[HOL4, ??????](http://hol-theorem-prover.org)*

[Release notes for the previous version](kananaskis-11.release.html)

</div>
