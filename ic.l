#!/usr/bin/picolisp /usr/lib/picolisp/lib.l
#
# Internet Chat(without relay) Server
#
# Code based on PicoLisp chat-server example by Alexander Burger
#
# (c) Alexander Sharikhin
# 20 June 17

### Configuration goes here ###
(setq *Port (port 4004))
(setq *DB-File "online.db")

# Code
(setq *online '("Alex" "bot")) # mock - replace by storing online users in db

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
  (T (not
      (filter '((name) (= *Name name)) *online) ) ) )

# Authed loop

# tell to all that user connected
(tell 'chat "+ " *Name) 

(task *Sock
   (in @
      (ifn (eof)
         (tell 'chat *Name ": " (line T)) 
         (tell 'chat "- " *Name)
         (bye) ) ) )
(wait)
