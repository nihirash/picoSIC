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

# DB method for user list 
(de create-user-record (name)
   (new!
      '(+User)
      'ky
      (genKey 'ky '+User)
      'nm
      name ) )

(de to-list (This)
   (list (: nm)) )

(de is-free (nick)
   (= NIL (db 'nm '+User nick)) )

(de get-online NIL
   (mapcar to-list (collect 'ky '+User)) )

(de delete-user-record (nick)
   (lose!> (db 'nm '+User nick)) )

# Broadcasting.
(de chat Lst
   (out *Sock (mapc prin Lst) (prinl)) )

# Connection loop
(loop
   (setq *Sock (listen *Port))
   (NIL (fork) (close *Port))
   (close *Sock) )

# Auth
(loop
   (out *Sock (prinl "AUTH ") (flush))
   (in *Sock (setq *Name (line T)))
   (T (is-free *Name)) )

# Authed loop
(create-user-record *Name)

# on connect list all online users
(out *Sock
   (mapc
      '((usr) (prin "+") (prinl usr))
      (get-online) )
   (prinl) )

# tell to all that user connected
(tell 'chat "+" *Name) 

# Send message. In our socket too
(de send-message (msg)
   (out *Sock
      (prinl "*" *Name "> " msg)
      (tell 'chat "*" *Name "> " msg) ) ) 

# Chat loop
(task
   *Sock
   (in @
      (ifn (eof)
         (send-message (line T))
         (tell 'chat "-" *Name)
         (delete-user-record *Name)
         (bye) ) ) )
(wait)
