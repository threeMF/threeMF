//
//  TMFLog.h
//
// Copyright (c) 2013 Martin Gratzer, http://www.mgratzer.com
// All rights reserved.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.
//
// This file is part of 3MF http://threemf.com
//

#ifndef TMFLog_h
#define TMFLog_h

// Local debug logging, inspired by https://github.com/robbiehanson/CocoaLumberjack

#define TMF_LOG_FLAG_ERROR    (1 << 0)
#define TMF_LOG_FLAG_WARN     (1 << 1)
#define TMF_LOG_FLAG_INFO     (1 << 2)
#define TMF_LOG_FLAG_VERBOSE  (1 << 3)

#define TMFLog(format, ...)               NSLog(format, ##__VA_ARGS__);
#define TMFLogWLvl(level, format, ...)    if(TMFLogLevel & level) { TMFLog((@"" format), ##__VA_ARGS__) }

#define TMFLogError(format, ...)          TMFLogWLvl(TMF_LOG_FLAG_ERROR,   format, ##__VA_ARGS__)
#define TMFLogWarn(format, ...)           TMFLogWLvl(TMF_LOG_FLAG_WARN,    format, ##__VA_ARGS__)
#define TMFLogInfo(format, ...)           TMFLogWLvl(TMF_LOG_FLAG_INFO,    format, ##__VA_ARGS__)
#define TMFLogVerbose(format, ...)        TMFLogWLvl(TMF_LOG_FLAG_VERBOSE, format, ##__VA_ARGS__)
#define TMFLogTrace()                     TMFLog(@"%s [Line %d]", __PRETTY_FUNCTION__, __LINE__)
#define TMFLogStackTrace()                TMFLog(@"%@", [NSThread callStackSymbols])

#define TMF_LOG_LEVEL_OFF     0
#define TMF_LOG_LEVEL_ERROR   (TMF_LOG_FLAG_ERROR)
#define TMF_LOG_LEVEL_WARN    (TMF_LOG_FLAG_ERROR | TMF_LOG_FLAG_WARN)
#define TMF_LOG_LEVEL_INFO    (TMF_LOG_FLAG_ERROR | TMF_LOG_FLAG_WARN | TMF_LOG_FLAG_INFO)
#define TMF_LOG_LEVEL_VERBOSE (TMF_LOG_FLAG_ERROR | TMF_LOG_FLAG_WARN | TMF_LOG_FLAG_INFO | TMF_LOG_FLAG_VERBOSE)

static const int TMFLogLevel = TMF_LOG_LEVEL_OFF;

#endif

