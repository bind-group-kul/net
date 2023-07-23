       
function Mat_data_type = getData_type(data_type, data_size)




if ( strcmp(data_type , 'unsigned fixed' ))
           
             dataKind = 'MEEG_DATA_FIXED_KIND';
             dataSign = 'MEEG_DATA_UNSIGNED_SIGN';
           
else if ( ( strcmp(data_type , 'signed fixed')) || ( strcmp(data_type , 'fixed')))
           
             dataKind = 'MEEG_DATA_FIXED_KIND';
             dataSign = 'MEEG_DATA_SIGNED_SIGN';
           
         else if ( strcmp(data_type , 'floating' ) || strcmp(data_type , 'float' ))
           
             dataKind = 'MEEG_DATA_FLOATING_KIND';
             dataSign = 'MEEG_DATA_SIGNED_SIGN';
             end

    end
end



 switch ( dataSign )
   
   case 'MEEG_DATA_SIGNED_SIGN'
     
   switch( dataKind )
     
     case 'MEEG_DATA_FIXED_KIND'
       
%          if ( data_size ==  1) %sizeof(signed char) )
%        Mat_data_type =  'schar';%MEEG_DATA_SIGNED_CHAR;
%           else if ( data_size == 2)%sizeof(signed short) )
%        Mat_data_type = 'int16';%MEEG_DATA_SIGNED_SHORT;
%                else if ( data_size == 4)%sizeof(signed int) )
%        Mat_data_type = 'int32';%MEEG_DATA_SIGNED_INT;
%                      else if ( data_size == 8)%sizeof(signed long int) )
%        Mat_data_type = 'int64';%MEEG_DATA_SIGNED_LONG;
%                             else
%        error ('Invalid dataSize');
%                          
       switch(data_size)
           case 1
            Mat_data_type =  'schar';
           case 2
               Mat_data_type =  'int16';
           case 4
               Mat_data_type =  'int32';
           case 8
               Mat_data_type =  'int64';
           otherwise 
              error ('Invalid dataSize');
       end
     

     case 'MEEG_DATA_FLOATING_KIND'
       
%          if ( data_Size == 4)%sizeof(float) )
%        Mat_data_type = 'float32';%MEEG_DATA_FLOAT;
%          else if ( data_size == 8)%sizeof(double) )
%        Mat_data_type = 'float64';%MEEG_DATA_DOUBLE;
%                  else
%        error ('Invalid dataSize');  
%               return;
%              end
%    
        switch(data_size)
           case 4
               Mat_data_type =  'float32';
           case 8
               Mat_data_type =  'float64';
           otherwise 
              error ('Invalid dataSize');
       end
     


   

       case 'MEEG_DATA_UNSIGNED_SIGN'
      switch( dataKind )
     
        case 'MEEG_DATA_FIXED_KIND'
       
%          if ( data_size == 1)%sizeof(unsigned char) )
%        Mat_data_type = 'uchar';%MEEG_DATA_UNSIGNED_CHAR;
%           else if ( data_size == 2)%sizeof(unsigned short) )
%        Mat_data_type = 'uint16';%MEEG_DATA_UNSIGNED_SHORT;
%                else if ( data_size == 4)%sizeof(unsigned int) )
%        Mat_data_type = 'uint32';%MEEG_DATA_UNSIGNED_INT;
%                     else if ( data_size == 8)%sizeof(unsigned long int) )
%        Mat_data_type = 'uint64';%MEEG_DATA_UNSIGNED_LONG;
%                         else
%                          error ('Invalid dataSize');       
%                          return;
%                         end
%                    end
%               end

        switch(data_size)
           case 1
            Mat_data_type =  'uchar';
           case 2
               Mat_data_type =  'uint16';
           case 4
               Mat_data_type =  'uint32';
           case 8
               Mat_data_type =  'uint64';
           otherwise 
              error ('Invalid dataSize');
       end
     


       
           case 'MEEG_DATA_FLOATING_KIND'
       
%           if ( data_size == 4)%sizeof(float) )
%             Mat_data_type = 'float32';%MEEG_DATA_FLOAT;
%            else if ( data_size == 8)%sizeof(double) )
%             Mat_data_type = 'float64'; %MEEG_DATA_DOUBLE;
%                else
%                  error ('Invalid dataSize');       
%                   return;
%                end
          switch(data_size)
           case 4
               Mat_data_type =  'float32';
           case 8
               Mat_data_type =  'float64';
           otherwise 
              error ('Invalid dataSize');
           end
     
     

end
   end
 end
end
