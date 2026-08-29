"""core/ schemas — request and response models per docs/API_CONTRACT.md §5–§15,
written by whoever owns the endpoint.

OWNER: Shreekumar owns the package; each schema module is written by the owner of
the endpoint it serves, named in that endpoint's router docstring.

Empty on purpose. Shapes that cross a module boundary do not belong here — they
belong in app/contracts/, which is frozen. This package is for shapes that are
only ever one endpoint's wire format.
"""
