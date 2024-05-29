/*
Copyright (C) 1997-2008 ZSNES Team ( zsKnight, _Demo_, pagefault, Nach )

http://www.zsnes.com
http://sourceforge.net/projects/zsnes
https://zsnes.bountysource.com

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
version 2 as published by the Free Software Foundation.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
*/

#ifndef WINLINK_H
#define WINLINK_H

#include <windows.h>

typedef HRESULT(WINAPI* lpDirectDrawCreateEx)(GUID FAR* lpGuid, LPVOID* lplpDD, REFIID iid,
    IUnknown FAR* pUnkOuter);

#ifdef __cplusplus
extern "C" {
#endif
extern BYTE changeRes;
extern unsigned int BitConv32Ptr;
extern unsigned int RGBtoYUVPtr;
extern unsigned short resolutn;
extern BYTE PrevRes;
extern BYTE hqFilterlevel;
extern WORD totlines;
extern DWORD CurMode;
extern DWORD WindowWidth;
extern DWORD WindowHeight;
extern BYTE BitDepth;
extern DWORD GBitMask;
extern WORD Refresh;
extern DWORD FirstVid;
extern DWORD FirstFull;
extern DWORD DMode;
extern DWORD SMode;
extern DWORD DSMode;
extern DWORD NTSCMode;
extern DWORD prevHQMode;
extern DWORD prevNTSCMode;
extern DWORD prevScanlines;
extern HWND hMainWindow;
extern BYTE curblank;
extern WORD totlines;
extern DWORD FullScreen;
extern RECT rcWindow;
extern RECT BlitArea;
extern BYTE AltSurface;
extern lpDirectDrawCreateEx pDirectDrawCreateEx;
extern BYTE* SurfBuf;
extern int X;
extern DWORD newmode;
extern WINDOWPLACEMENT wndpl;
extern RECT rc1;

void Clear2xSaIBuffer();
void FrameSemaphore(void);
void clear_display();
char CheckTVRatioReq();
void KeepTVRatio();

void CheckAlwaysOnTop(void);
void CheckPriority(void);
void CheckScreenSaver(void);
void DisplayWIPDisclaimer(void);
void DoSleep(void);
void MinimizeWindow(void);
void PasteClipBoard(void);
void SetMouseMaxX(int MaxX);
void SetMouseMaxY(int MaxY);
void SetMouseMinX(int MinX);
void SetMouseMinY(int MinY);
void SetMouseX(int X);
void SetMouseY(int Y);
void WinUpdateDevices(void);
void initDirectDraw(void);
void reInitSound(void);

extern BOOL ctrlptr;
extern char* CBBuffer;
extern u4 CBLength;

#ifdef __cplusplus
}

BOOL ReInitSound();
void ReleaseDirectDraw();
void DDDrawScreen();
#endif

#endif
