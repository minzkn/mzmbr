/* Code by Cho JaeHyuk */

#include <stdio.h>
#include <conio.h>
#include <dos.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>
#include <io.h>
#include <dir.h>

#define MZ_BUFFERSIZE        512

typedef struct
{
 signed char MZ[2];
 unsigned int size_mod;
 unsigned int size_div;
 unsigned int relocate;
 unsigned int headsize;
 unsigned int minm_mem;
 unsigned int maxm_mem;
 unsigned int init_sss;
 unsigned int init_spp;
 unsigned int checksum;
 unsigned int init_ipp;
 unsigned int init_css;
 unsigned int startoff;
 unsigned int overlayn;
}EXEC;

signed char  *g_defaultexe=".EXE";
signed char  *g_defaultbin=".BIN";
signed char   g_exename[MAXPATH];
signed char   g_binname[MAXPATH];
signed int    g_check;
unsigned char g_buffer[MZ_BUFFERSIZE];

void Usage(void)
{
           printf("\nUSAGE: EXE2MZ <EXEC_file> <BIN_file>\n");
}

void DefaultExt(signed char *s_dest, signed char *s_src, signed char *s_defext)
{
 signed char s_drive[MAXDRIVE], s_dir[MAXDIR], s_file[MAXFILE], s_ext[MAXEXT];
           fnsplit(s_src, s_drive, s_dir, s_file, s_ext);
           strcpy(s_dest, s_drive);
           strcat(s_dest, s_dir);
           strcat(s_dest, s_file);
           strcat(s_dest, s_defext);
}

void ConvertMZ(void)
{
 FILE          *s_fr, *s_fw;
 EXEC          EXEC_header;
 unsigned long s_codestart;
 unsigned long s_codesize;
           s_fr=fopen(g_exename, "rb");
           if(s_fr==NULL)
           {
            printf("\nError: Can not open [READ] - \`%s\'.\n", g_exename);
            return;
           }
           //printf("\nMessage: Convert \`%s\' to \`%s\'.\n", g_exename, g_binname);

           g_check=fread(&EXEC_header, sizeof(EXEC), 1, s_fr);
           if(g_check==0)
           {
            printf("\nError: Can not read.\n");
            fclose(s_fr);
            return;
           }

           g_check=strncmp(EXEC_header.MZ, "MZ", 2);
           if(g_check!=0)
           {
            printf("\nError: Found not signature\(\"MZ\"\).\n");
            fclose(s_fr);
            return;
           }

           if(EXEC_header.relocate)
           {
            printf("\nError: File has relocatable information.\n");
            fclose(s_fr);
            return;
           }

           //if(EXEC_header.init_sss||EXEC_header.init_spp)printf("\nWarnning: Found stack information\n");
           //if(EXEC_header.init_css)printf("\nWarnning: CS offset is not zero\n");
           //if(EXEC_header.init_ipp)printf("\nWarnning: IP offset is not zero\n");

           s_codestart=((unsigned long)EXEC_header.headsize)<<4;
           g_check=EXEC_header.size_mod;
           if(g_check==0)g_check=512;
           s_codesize=(((unsigned long)(EXEC_header.size_div-1))*512L)+((unsigned long)g_check)-s_codestart;
           if(s_codesize>65536L)printf("\nWarnning: Size over! [\(%lu\)>64KByte]\n", s_codesize);

           g_check=fseek(s_fr, s_codestart+EXEC_header.init_ipp, SEEK_SET);
           if(g_check!=0)
           {
            printf("\nError: Can not seek.\n");
            fclose(s_fr);
            return;
           }

           s_fw=fopen(g_binname, "wb");
           if(s_fw==NULL)
           {
            printf("\nError: Can not open [WRITE] - \`%s\'.\n", g_binname);
            fclose(s_fr);
            return;
           }

           s_codesize-=(unsigned long)EXEC_header.init_ipp;
           while(s_codesize>0L)
           {
            if(s_codesize<=512)
            {
             fread(g_buffer, (size_t)s_codesize, 1, s_fr);
             fwrite(g_buffer, (size_t)s_codesize, 1, s_fw);
             break;
            }
            else
            {
             fread(g_buffer, 512, 1, s_fr);
             fwrite(g_buffer, 512, 1, s_fw);
            }
            s_codesize-=512;
           }

           fclose(s_fr);
           fclose(s_fw);
           //printf("Success!\n");
}

void main(signed int s_argc, signed char *s_argv[])
{
           //printf("EXE2MZ (v1.00) Copyright (c) 1998 by MINZ team\nCode by Cho JaeHyuk [Pager:012-846-6420]\n");
           if(s_argc!=2&&s_argc!=3)Usage();
           else
           {
            if(access(s_argv[1], 0)==0)strcpy(g_exename, s_argv[1]);
            else DefaultExt(g_exename, s_argv[1], g_defaultexe);
            if(s_argc==3)strcpy(g_binname, s_argv[2]);
            else DefaultExt(g_binname, g_exename, g_defaultbin);
            strupr(g_exename);
            strupr(g_binname);
            g_check=strcmp(g_exename, g_binname);
            if(g_check==0)printf("\nError: EXEC_file == BIN_file\n");
            else ConvertMZ();
           }
}

/* End of source */
