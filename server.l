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
   (if nick (lose!> (db 'nm '+User nick))) )

# Broadcasting.
(de chat Lst
   (out *Sock (mapc prin Lst) (prinl)) )

# Private message
(de private-msg (From To Msg)
   (when (and (= To *Name) Msg)
      (out *Sock (prin "@" From "> " Msg) (prinl)) ) )

# Connection loop
(loop
   (setq *Sock (listen *Port))
   (NIL (fork) (close *Port))
   (close *Sock) )

# Auth
(loop
   (out *Sock (prinl "AUTH") (flush))
   (in *Sock (setq *Auth (line T)))
   (setq *AuthFields (mapcar pack (split (chop *Auth) " ")))
   (T (is-free (car *AuthFields))) )

(setq *Name (car *AuthFields))

(unless *Name (bye)) 

# Authed loop
(create-user-record *Name)

# on connect list all online users
(out *Sock
   (prinl "OK")
   (mapc
      '((usr) (prin "+") (prinl usr))
      (get-online) )
   (prinl) )

# tell to all that user connected
(tell 'chat "+" *Name) 

# Send message. In our socket too
# Removing non-symbolic chars and not sent empty strings
(de send-public-message (Msg)
   (setq Msg
      (pack
         (filter
            '((Chr) (>= (char Chr) 32))
            (chop Msg) ) ) )
   (when (pack (split (chop Msg) " "))
      (tell 'chat "*" *Name "> " Msg) ) )

# Send private message
(de send-private-message (To Msg)
   (when Msg (tell 'private-msg *Name To Msg)) )

# Send message
(de send-message (Msg)
   (setq MsgChars (chop Msg))
   (ifn (= (car MsgChars) "@")
      (send-public-message Msg)
      (send-private-message
         (pack (car (split (cdr MsgChars) " ")))
         (glue " " (cdr (split (cdr MsgChars) " "))) ) ) )


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
