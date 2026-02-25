art_line0  db 80 dup (32)

art_line1  db 80 dup (32)

art_line2  db 80 dup (32)

art_line3  db 80 dup (32)

art_line4  db "                                                                      "
          db 80 - ($ - art_line4) dup (32)

art_line5  db "                                                                      "
          db 80 - ($ - art_line5) dup (32)

art_line6  db "                                 ..+##****##=...        ...++.        "
          db 80 - ($ - art_line6) dup (32)

art_line7  db "                              .+#*=           -+-..  :-#%*            "
          db 80 - ($ - art_line7) dup (32)

art_line8  db "                            :++:.                .=+@#+               "
          db 80 - ($ - art_line8) dup (32)

art_line9  db "                          .+*:.                -#@@+:                 "
          db 80 - ($ - art_line9) dup (32)

art_line10 db "                         :++.                =%@@+.  .                "
          db 80 - ($ - art_line10) dup (32)

art_line11 db "                        .=+.                -%@@-.   ..               "
          db 80 - ($ - art_line11) dup (32)

art_line12 db "                  :*%@@@@@@@@@@@@@%        .*@@-                      "
          db 80 - ($ - art_line12) dup (32)

art_line13 db "     ....-*@@@%#@@@@@@@@@@@@@@@@@@@@@+.    +@@=                       "
          db 80 - ($ - art_line13) dup (32)

art_line14 db " ..:        .-:.        -+:    +%@@@@@@%:..*@*:   ..:.                "
          db 80 - ($ - art_line14) dup (32)

art_line15 db "                        :+-       *@@@@@@%*@@*=*@@@*:                 "
          db 80 - ($ - art_line15) dup (32)

art_line16 db "                         -=.       .+@@@@@@@@@@@*=.                   "
          db 80 - ($ - art_line16) dup (32)

art_line17 db "                          --.   .*#@@@@@@@#=-:.                       "
          db 80 - ($ - art_line17) dup (32)

art_line18 db "                           .=:.:.-@-:::.                             "
          db 80 - ($ - art_line18) dup (32)

art_line19 db "                             .=.                                      "
          db 80 - ($ - art_line19) dup (32)

art_line20 db "                                .:..                                  "
          db 80 - ($ - art_line20) dup (32)

art_line21 db "                                                                      "
          db 80 - ($ - art_line21) dup (32)

art_line22 db "                                                                      "
          db 80 - ($ - art_line22) dup (32)

art_line23 db "                                                                      "
          db 80 - ($ - art_line23) dup (32)

art_line24 db "                                                                      "
          db 80 - ($ - art_line24) dup (32)


Art_lines_arr dw art_line0,  art_line1,  art_line2,  art_line3,  art_line4,  art_line5,  art_line6  
              dw art_line7,  art_line8,  art_line9,  art_line10, art_line11, art_line12, art_line13
              dw art_line14, art_line15, art_line16, art_line17, art_line18, art_line19, art_line20
              dw art_line21, art_line22, art_line23, art_line24

Lines_count = 25