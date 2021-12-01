# undup
Finds duplicate files when given directories as arguments

Proof of concept file deduplicator for BASH. Doesn't actually dedupe, just informs you of matches.

It has not been tuned for performance in any way, just code "simplicity" and showing someone that it could be done.

# Dependencies:
- `stat`
- `awk`
- `seq`
- `sha256sum`
- `wc`
