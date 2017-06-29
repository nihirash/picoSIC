#!/usr/bin/picolisp /usr/lib/picolisp/lib.l
#
# picoSIP Internet Chat Client
#
# (c) Alexander Sharikhin
# 21 june 17


(load "@lib/misc.l")

# Starting params 

(setq *Host (opt))
(setq *Port 4004)
(setq *Nick (opt))
(setq *Online NIL)

# Misc funcs 

(de usage NIL
   (prinl "client.l <host> <nick>")
   (bye) )

(de termlog (Line)
   (do (length *Line)
      (prin "^H ^H") )
   (prinl (tim$ (time)) " " Line)
   (prin *Line) ) 

(de is-get (What)
   (= What (in *Connection (line T))) )


(if (not (and *Host *Nick)) (usage))

(setq *Connection (connect *Host *Port))

(unless *Connection (quit (cons "Can't connect to " *Host)))

# AUTH state

(de auth-wait-loop NIL
   (ifn (is-get "AUTH") (auth-wait-loop)) )  

(auth-wait-loop)

(out *Connection (prinl *Nick) (flush))

(in *Connection (unless (is-get "OK") (quit "Auth failed")))

# Chatting state

(setq *Line NIL)

# Received messages 
(task
   (in *Connection
      (loop
         (setq
            *In (chop (line T))
            *Cmd (car *In)
            *Str (pack (cdr *In)) )
         (case *Cmd
            ("*" (prinl *Str))
            ("+" (prinl *Str " is online") (push '*Online *Str))
            ("-" (prinl *Str " is offline") (del *Str '*Online)) ) ) ) )
