scenario = "dimon";      
pcl_file = "eyecalibration.pcl";
 
#no_logfile = true;
#active_buttons = 2;
#button_codes = 98,99; 
write_codes = true; 
pulse_width = 1000;
#-------------------------------------------------------
begin;

picture {} default;   
 
trial {
 

   picture {
      text { caption = "+";      font_size = 50;   
          };
      x = 0; y = 0;  
   }pic1; 
   
   port_code = 1;
   time = 0; 
   duration =1000;  
}trial1; 
trial {
   picture {
      text { caption = "+";      font_size = 50;  };
      x = -500; y = 0;  
   }pic2;  
   time = 0;
   duration = 1000 ;
   port_code = 2 ;
}trial4 ;
trial {  
   picture {
      text { caption = "+";      font_size = 50;  };
      x = 500 ; y = 0;
   }pic3;
   time = 0;
   duration = 1000;  
   port_code = 3;
}trial5 ;
trial {   
   picture {
      text { caption = "+";      font_size = 50;  };
      x = 0; y = 400; 
   }pic4 ;
   time = 0;
   duration = 1000;
   port_code = 4 ;
}trial6 ;
trial {
   picture {  
      text { caption = "+";      font_size = 50;  };
      x = 0; y = -400;
   }pic5;
   time = 0;
   duration = 1000; 
   port_code = 5;
}trial7;                         



