# Part 5 — Video and channel management

Implemented Profile links to My channel/Manage videos; owner video list; add/edit forms for title, description, HTTPS video and optional thumbnail URLs, category; delete confirmation; unsaved-change confirmation in video editor; channel name/description/avatar editing; public channel page from video details.

Home/Search refresh on repository changes. Channel updates propagate to existing video records. Ownership is checked in the mock repository for video edits/deletes. Video deletion removes related mock comments. History integration follows in Part 6.

Try: Profile > Login > My channel or Manage videos > +. Demo account demo@minitube.app / Demo1234; second owner studio@minitube.app / Studio1234. New registrations start with no videos. Data resets on application restart. API/backend and persistent media uploads are not included; use direct HTTPS MP4 URLs. Thumbnail/avatar URLs are stored; current artwork remains category/initial placeholders. Channel edits are saved only by Save channel; leaving the channel form discards unsaved input.

Validation: flutter analyze clean; 6 automated tests covering previous features plus CRUD ownership, channel propagation and dependent comment deletion. Manual UI/device verification is still required.
