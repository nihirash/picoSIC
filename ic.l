#!/usr/bin/picolisp /usr/lib/picolisp/lib.l
#
# Internet Chat(without relay) Server
#
# Code based on PicoLisp chat-server example by Alexander Burger
#
# (c) Alexander Sharikhin
# 20 June 17

(load "@lib/misc.l" "@lib/btree.l" "@lib/db.l")

### Configuration goes here ###
(setq *Port (port 4004))

# Code
(pool (tmp "online.db"))

# User entity & methods

(class +User +Entity)
(rel ky (+Need +Key +Number))
(rel nm (+Ref +String))

# in db
(de create-user-record(name)
   (new! '(+User) 
	'ky (genKey 'ky '+User)
	'nm name))

(de to-list(This)
    (list (: nm)))

(de is-free(name)
    (= NIL (db 'nm '+User name)))

(de get-online ()
    (mapcar to-list (collect 'ky '+User)))

# Broadcasting.
(de chat Lst 
   (out *Sock
      (mapc prin Lst)
      (prinl) ) )

# Connection loop
(loop
   (setq *Sock (listen *Port))
   (NIL (fork) (close *Port))
   (close *Sock) )

# Auth
(loop
 (out *Sock
  (prinl "AUTH ")
  (flush) )
  (in *Sock (setq *Name (line T)))
  (T (is-free *Name)))

# Authed loop
(create-user-record *Name)

(out *Sock
 (prinl "Online: ")
 (mapcar prinl (get-online))
 (prinl))

# tell to all that user connected
(tell 'chat "+ " *Name) 

(task *Sock
   (in @
      (ifn (eof)
         (tell 'chat *Name ": " (line T)) 
         (tell 'chat "- " *Name)
         (bye) ) ) )
(wait)
