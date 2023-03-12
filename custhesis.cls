%
% Copyright (C) 2023 by CVIR lab of CUST <http://www.cvirlab.com/>
%
% This file may be distributed and/or modified under the
% conditions of the LaTeX Project Public License, either version 1.3c
% of this license or (at your option) any later version.
% The latest version of this license is in
%    https://www.latex-project.org/lppl.txt
% and version 1.3c or later is part of all distributions of LaTeX
% version 2008 or later.
%

\NeedsTeXFormat{LaTeX2e}[2017/04/15]
\newcommand\custhesisversion{v1.0.4}%
\ProvidesClass{custhesis}[2023/02/15 {\custhesisversion} CUST thesis template]

% 报错和警告
\newcommand\cust@error[1]{%
  \ClassError{custhesis}{#1}{}%
}
\newcommand\cust@warning[1]{%
  \ClassWarning{custhesis}{#1}%
}

% 检查 \LaTeXe{} kernel 版本
\@ifl@t@r\fmtversion{2017/04/15}{}{
  \cust@error{%
    TeX Live 2017 or later version is required to compile this document%
  }
}

% 检查编译引擎，要求使用 XeLaTeX 或 LuaLaTeX。
\RequirePackage{iftex}
\ifXeTeX\else
  \ifLuaTeX\else
    \cust@error{XeLaTeX or LuaLaTeX is required to compile this document}
  \fi
\fi


% \subsection{处理选项}

\RequirePackage{kvdefinekeys}
\RequirePackage{kvsetkeys}
\RequirePackage{kvoptions}

% 提供一个 \cs{custsetup} 命令支持 \emph{key-value} 的方式来设置。
\let\cust@setup@hook\@empty
\newcommand\custsetup[1]{%
  \let\cust@setup@hook\@empty
  \kvsetkeys{cust}{#1}%
  \cust@setup@hook
}

% 同时用 \emph{key-value} 的方式来定义这些接口：
% \begin{latex}
%   \cust@define@key{
%     <key> = {
%       name = <name>,
%       choices = {
%         <choice1>,
%         <choice2>,
%       },
%       default = <default>,
%       code = <code>,
%     },
%   }
% \end{latex}

% 其中 |choices| 设置允许使用的值，默认为第一个（或者 \meta{default}）；
% \meta{code} 是相应的内容被设置时执行的代码。

\newcommand\cust@define@key[1]{%
  \kvsetkeys{cust@key}{#1}%
}
\kv@set@family@handler{cust@key}{%
%
% \cs{custsetup} 会将 \meta{value} 存到 \cs{cust@\meta{key}}，
% 但是宏的名字包含 “-” 这样的特殊字符时不方便直接调用，比如 |key = math-style|，
% 这时可以用 |name| 设置 \meta{key} 的别称，比如 |key = math@style|，
% 这样就可以通过 \cs{cust@math@style} 来引用。
% |default| 是定义该 \meta{key} 时默认的值，缺省为空。
%
  \@namedef{cust@#1@@name}{#1}%
  \def\cust@@default{}%
  \def\cust@@choices{}%
  \kv@define@key{cust@value}{name}{%
    \@namedef{cust@#1@@name}{##1}%
  }%
  %
  % 由于在定义接口时，\cs{cust@\meta{key}@@code} 不一定有定义，
  % 而且在文档类/宏包中还有可能对该 |key| 的 |code| 进行添加。
  % 所以 \cs{cust@\meta{key}@@code} 会检查如果在定义文档类/宏包时则推迟执行，否则立即执行。
  %
  \@namedef{cust@#1@@check}{}%
  \@namedef{cust@#1@@code}{}%
  %
  % 保存下 |choices = {}| 定义的内容，在定义 \cs{cust@\meta{name}} 后再执行。
  %
  \kv@define@key{cust@value}{choices}{%
    \def\cust@@choices{##1}%
    \@namedef{cust@#1@@reset}{}%
    %
    % \cs{cust@\meta{key}@check} 检查 |value| 是否有效，
    % 并设置 \cs{ifcust@\meta{name}@\meta{value}}。
    %
    \@namedef{cust@#1@@check}{%
      \@ifundefined{%
        ifcust@\@nameuse{cust@#1@@name}@\@nameuse{cust@\@nameuse{cust@#1@@name}}%
      }{%
        \cust@error{Invalid value "#1 = \@nameuse{cust@\@nameuse{cust@#1@@name}}"}%
      }%
      \@nameuse{cust@#1@@reset}%
      \@nameuse{cust@\@nameuse{cust@#1@@name}@\@nameuse{cust@\@nameuse{cust@#1@@name}}true}%
    }%
  }%
  \kv@define@key{cust@value}{default}{%
    \def\cust@@default{##1}%
  }%
  \kvsetkeys{cust@value}{#2}%
  \@namedef{cust@\@nameuse{cust@#1@@name}}{}%
  %
  % 第一个 \meta{choice} 设为 \meta{default}，
  % 并且对每个 \meta{choice} 定义 \cs{ifcust@\meta{name}@\meta{choice}}。
  %
  \kv@set@family@handler{cust@choice}{%
    \ifx\cust@@default\@empty
      \def\cust@@default{##1}%
    \fi
    \expandafter\newif\csname ifcust@\@nameuse{cust@#1@@name}@##1\endcsname
    \expandafter\g@addto@macro\csname cust@#1@@reset\endcsname{%
      \@nameuse{cust@\@nameuse{cust@#1@@name}@##1false}%
    }%
  }%
  \kvsetkeys@expandafter{cust@choice}{\cust@@choices}%
  %
  % 将 \meta{default} 赋值到 \cs{cust@\meta{name}}，如果非空则执行相应的代码。
  %
  \expandafter\let\csname cust@\@nameuse{cust@#1@@name}\endcsname\cust@@default
  \expandafter\ifx\csname cust@\@nameuse{cust@#1@@name}\endcsname\@empty\else
    \@nameuse{cust@#1@@check}%
  \fi
  %
  % 定义 \cs{custsetup} 接口。
  %
  \kv@define@key{cust}{#1}{%
    \@namedef{cust@\@nameuse{cust@#1@@name}}{##1}%
    \@nameuse{cust@#1@@check}%
    \@nameuse{cust@#1@@code}%
  }%
}

% 定义接口向 |key| 添加 |code|：

\newcommand\cust@option@hook[2]{%
  \expandafter\g@addto@macro\csname cust@#1@@code\endcsname{#2}%
}

\cust@define@key{
  degree = {
    choices = {
      doctor,
      master,
      bachelor,
    },
    default = doctor,
  },
  degree-type = {
    name = degree@type,
    choices = {
      academic,
      professional,
    },
    default = academic,
  },
  main-language = {
    name = main@language,
    choices = {
      chinese,
      english,
    },
    default = chinese,
  },
  language = {
    choices = {
      chinese,
      english,
    },
    default = chinese,
  },
  system = {
    choices = {
      auto,
      mac,
      unix,
      windows,
    },
    default = auto,
  },
  fontset = {
    choices = {
      auto,
      windows,
      mac,
      ubuntu,
      fandol,
      none,
    },
    default = auto,
  },
  font = {
    choices = {
      auto,
      times,
      termes,
      stix,
      xits,
      libertinus,
      newcm,
      lm,
      newtx,
      none,
    },
    default = auto,
  },
  cjk-font = {
    name = cjk@font,
    choices = {
      auto,
      windows,
      mac,
      noto,
      fandol,
      none,
    },
    default = auto,
  },
  math-font = {
    name = math@font,
    choices = {
      auto,
      stix,
      xits,
      libertinus,
      newcm,
      cm,
      lm,
      newtx,
      none,
    },
    default = auto,
  },
  math-style = {
    name = math@style,
    choices = {
      GB,
      ISO,
      TeX,
    },
  },
  uppercase-greek = {
    name = uppercase@greek,
    choices = {
      italic,
      upright,
    },
  },
  less-than-or-equal = {
    name = leq,
    choices = {
      slanted,
      horizontal,
    },
  },
  integral = {
    choices = {
      upright,
      slanted,
    },
  },
  integral-limits = {
    name = integral@limits,
    choices = {
      true,
      false,
    },
  },
  partial = {
    choices = {
      upright,
      italic,
    },
  },
  math-ellipsis = {
    name = math@ellipsis,
    choices = {
      centered,
      lower,
      AMS,
    },
  },
  real-part = {
    name = real@part,
    choices = {
      roman,
      fraktur,
    },
  },
  cite-style = {
    name = cite@style,
    choices = {
      super,
      inline,
      authoryear,
    },
  },
  output = {
    choices = {
      print,
      electronic,
    },
    default = print,
  },
  section-style = {
    name = section@style,
    choices = {
      chinese,
      arabic,
    },
    default = chinese,
  },
  badge-color = {
    name = badge@color,
    choices = {
      blue,
      black,
    },
    default = blue,
  },
}

% 将 \cust@cite@style 置空方便后续进行判断。
\def\cust@cite@style{}

\newif\ifcust@degree@graduate
\newcommand\cust@set@graduate{%
  \ifcust@degree@bachelor
    \cust@degree@graduatefalse
  \else
    \cust@degree@graduatetrue
  \fi
}
\cust@set@graduate
\cust@option@hook{degree}{%
  \cust@set@graduate
}

% 使用 \pkg{kvoptions} 提供的 key-value 接口，
\SetupKeyvalOptions{
  family  = cust,
  prefix  = cust@,
  setkeys = \kvsetkeys,
}

% 设置默认 \option{openany}。
\DeclareBoolOption[false]{openright}
\DeclareComplementaryOption{openany}{openright}

% 载入 \cls{ctexbook}。
\DeclareDefaultOption{\PassOptionsToClass{\CurrentOption}{ctexbook}}
\ProcessKeyvalOptions*


% \subsection{加载文档类和宏包}

\ifcust@openright
  \PassOptionsToClass{openright}{book}
\else
  \PassOptionsToClass{openany}{book}
\fi

\ifcust@output@electronic
  \PassOptionsToClass{oneside}{book}
\fi
\PassOptionsToPackage{no-math}{fontspec}

% 载入 \cls{ctexbook} 文档类，注意要求为 2.4.9 或更高的版本。
\LoadClass[UTF8,a4paper,scheme=plain,zihao=-4,fontset=none]{ctexbook}[2017/04/01]

% 建议在模板开始处载入全部宏包，不要轻易改变加载顺序。
% \pkg{hyperref} 一般在最后加载。
\RequirePackage{etoolbox}
\RequirePackage{amsmath}
\RequirePackage{fontspec}[2017/03/31]
\RequirePackage{geometry}
\RequirePackage{graphicx}
\RequirePackage{fancyhdr}
\RequirePackage{color}
\RequirePackage{titletoc}
\RequirePackage{caption}
\RequirePackage[perpage]{footmisc}
\RequirePackage{url}
\RequirePackage{notoccite}
\RequirePackage{multirow}

% 如果用户在导言区未调用 \pkg{biblatex}，则自动调用 \pkg{natbib}。
\AtEndPreamble{
  \@ifpackageloaded{biblatex}{}{
    \RequirePackage{natbib}
  }
}

% 对冲突的宏包报错。
\RequirePackage{filehook}
\newcommand\cust@package@conflict[2]{
  \AtEndOfPackageFile*{#1}{%
    \AtBeginOfPackageFile*{#2}{%
      \cust@error{The "#2" package is incompatible with "#1"}%
    }%
  }%
}

\cust@package@conflict{biblatex}{bibunits}
\cust@package@conflict{biblatex}{chapterbib}
\cust@package@conflict{biblatex}{cite}
\cust@package@conflict{biblatex}{multibib}
\cust@package@conflict{biblatex}{natbib}

\cust@package@conflict{bibunits}{biblatex}
\cust@package@conflict{bibunits}{chapterbib}
\cust@package@conflict{bibunits}{multibib}

\cust@package@conflict{unicode-math}{amscd}
\cust@package@conflict{unicode-math}{amsfonts}
\cust@package@conflict{unicode-math}{amssymb}
\cust@package@conflict{unicode-math}{bbm}
\cust@package@conflict{unicode-math}{bm}
\cust@package@conflict{unicode-math}{eucal}
\cust@package@conflict{unicode-math}{eufrak}
\cust@package@conflict{unicode-math}{mathrsfs}
\cust@package@conflict{unicode-math}{newtxmath}
\cust@package@conflict{unicode-math}{upgreek}

\cust@package@conflict{natbib}{biblatex}
\cust@package@conflict{natbib}{cite}

\cust@package@conflict{newtxmath}{amsfonts}
\cust@package@conflict{newtxmath}{amssymb}
\cust@package@conflict{newtxmath}{unicode-math}
\cust@package@conflict{newtxmath}{upgreek}


% \pkg{amsthm} 需要在 \pkg{newtx} 前载入，参考 \pkg{newtx} 的文档。
\AtBeginOfPackageFile*{amsthm}{
  \@ifpackageloaded{newtxmath}{
    \cust@error{The "amsthm" package should be loaded before setting "newtxmath"}
  }{}
}%



% \subsection{处理语言}

% 定义 \cs{cust@main@language}，当在导言区修改 \option{language} 时，
% 保存为论文的主要语言；
% \cs{cust@reset@main@language} 则用于正文中恢复为主要语言。
%    \begin{macrocode}
\custsetup{main-language=\cust@language}%
\let\cust@main@language\cust@language

\cust@option@hook{language}{%
  \ifx\@begindocumenthook\@undefined\else
    \custsetup{main-language=\cust@language}%
    \let\cust@main@language\cust@language
  \fi
}
\newcommand\cust@reset@main@language{%
  \custsetup{language = \cust@main@language}%
  \let\cust@language\cust@main@language
}

% 带圈数字和星号使用中文字体。
\ifLuaTeX
  % ctex 将带圈数字 U+2460–U+24FF 归入字符范围 3（ALchar），这里改回范围 6（JAchar）
  \ltjdefcharrange{3}{%
    "2000-"243F, "2500-"27BF, "2900-"29FF, "2B00-"2BFF}
  \ltjdefcharrange{6}{%
    "2460-"24FF, "2E80-"2EFF, "3000-"30FF, "3190-"319F, "31F0-"4DBF,
    "4E00-"9FFF, "F900-"FAFF, "FE10-"FE1F, "FE30-"FE6F, "FF00-"FFEF,
    "1B000-"1B16F, "1F100-"1F2FF, "20000-"3FFFF, "E0100-"E01EF}
\else
  \ifXeTeX
    \xeCJKDeclareCharClass{CJK}{"2460 -> "2473}
    \xeCJKDeclareCharClass{CJK}{"2605}
  \fi
\fi

% 由于 Unicode 的一些标点符号是中西文混用的：
% U+00B7、U+2013、U+2014、U+2018、U+2019、
% U+201C、U+201D、U+2025、U+2026、U+2E3A，
% 所以要根据语言设置正确的字体。
% https://github.com/CTeX-org/ctex-kit/issues/389
\newcommand\cust@set@punctuations{%
  \ifcust@language@chinese
    \ifLuaTeX
      \ltjsetparameter{jacharrange={+9}}
    \else
      \ifXeTeX
        \xeCJKDeclareCharClass{FullLeft}{"2018, "201C}%
        \xeCJKDeclareCharClass{FullRight}{
          "00B7, "2019, "201D, "2013, "2014, "2025, "2026, "2E3A,
        }%
      \fi
    \fi
  \else
    \ifLuaTeX
      \ltjsetparameter{jacharrange={-9}}
    \else
      \ifXeTeX
        \xeCJKDeclareCharClass{HalfLeft}{"2018, "201C}%
        \xeCJKDeclareCharClass{HalfRight}{
          "00B7, "2019, "201D, "2013, "2014, "2025, "2026, "2E3A,
        }%
      \fi
    \fi
  \fi
}
\cust@set@punctuations
\cust@option@hook{language}{\cust@set@punctuations}

% 根据语言设置各章节的名称，只有在导言区设置 \option{language} 时会修改，
% 而在正文局部切换语言时则不变。

% speciality一词使用英式拼法，“acknowledgements”也保持一致。
\newcommand\cust@set@chapter@names{%
  \ifcust@main@language@chinese
    \def\contentsname{目录}%
    \def\listfigurename{插图清单}%
    \def\listtablename{表格清单}%
    \ctexset{
      chapter/name   = {第,章},
    }%
    \def\bibname{参考文献}%
    \def\appendixname{附录}%
    \def\cust@acknowledgements@name{致谢}%
    \def\cust@publication@name{在读期间发表的学术论文与取得的研究成果}%
    \newcommand\cust@notation@name{符号说明}%
  \else
    \def\contentsname{Contents}%
    \def\listfigurename{List of Figures}%
    \def\listtablename{List of Tables}%
    \ctexset{
      chapter/name   = {\chaptername\space},
    }%
    \def\bibname{Bibliography}%
    \def\appendixname{Appendix}%
    \def\cust@acknowledgements@name{Acknowledgements}%
    \def\cust@publication@name{Publications}%
    \def\cust@notation@name{Notation}%
  \fi
}
\cust@set@chapter@names
\cust@option@hook{main-language}{\cust@set@chapter@names}

% 这部分名称在正文中局部地修改语言时会发生变化。
\newcommand\cust@set@names{%
  \ifcust@language@chinese
    \def\figurename{图}%
    \def\tablename{表}%
  \else
    \def\figurename{Figure}%
    \def\tablename{Table}%
  \fi
}
\cust@set@names
\cust@option@hook{language}{\cust@set@names}


% \subsection{字体}

% 字号

% 正文字号12bp，研究生行距20bp，本科生行距22bp；
% 其他命令的行距按照相同的的比例设置，如表~\ref{tab:fontsize}。
% \begin{table}[htb]
%   \centering
%   \caption{标准字体命令与字号、行距的对应}
%   \label{tab:fontsize}
%   \begin{tabular}{lllll}
%     \toprule
%     字体命令          & 字号 & bp   & 研究生行距 & 本科生行距 \\
%     \midrule
%     \cs{tiny}         & 小六 & 6.5  & 10.83      & 11.92      \\
%     \cs{scriptsize}   & 六号 & 7.5  & 12.5       & 13.75      \\
%     \cs{footnotesize} & 小五 & 9    & 15         & 16.5       \\
%     \cs{small}        & 五号 & 10.5 & 17.5       & 19.25      \\
%     \cs{normalsize}   & 小四 & 12   & 20         & 22         \\
%     \cs{large}        & 小三 & 15   & 25         & 27.5       \\
%     \cs{Large}        & 小二 & 18   & 30         & 33         \\
%     \cs{LARGE}        & 二号 & 22   & 36.67      & 40.33      \\
%     \cs{huge}         & 小一 & 24   & 40         & 44         \\
%     \cs{Huge}         & 一号 & 26   & 43.33      & 47.67      \\
%     \bottomrule
%   \end{tabular}
% \end{table}
%
% 注意重定义 \normalsize 应在 \pkg{unicode-math} 的 \cs{setmathfont} 前。
\newcommand\cust@set@font@size{%
  \ifcust@degree@graduate
    \renewcommand\normalsize{%
      \@setfontsize\normalsize{12bp}{20bp}%
      \abovedisplayskip 12bp \@plus3bp \@minus7bp%
      \abovedisplayshortskip \z@ \@plus3bp%
      \belowdisplayshortskip 6.5bp \@plus3.5bp \@minus3bp%
      \belowdisplayskip \abovedisplayskip
      \let\@listi\@listI}%
    %
    % 注意第~\ref{sec:list} 节去掉了列表的间距，所以不再修改 \cs{@listi}。
  \else
    \renewcommand\normalsize{%
      \@setfontsize\normalsize{12bp}{22bp}%
      \abovedisplayskip 12bp \@plus3bp \@minus7bp%
      \abovedisplayshortskip \z@ \@plus3bp%
      \belowdisplayshortskip 6.5bp \@plus3.5bp \@minus3bp%
      \belowdisplayskip \abovedisplayskip
      \let\@listi\@listI}%
  \fi
  \normalsize
  \ifx\MakeRobust\@undefined \else
      \MakeRobust\normalsize
  \fi
}
\cust@set@font@size
\cust@option@hook{degree}{\cust@set@font@size}

% 设置行距的倍数为 1.25。
\linespread{1.25}\selectfont


% 检测系统
\ifcust@system@auto
  \IfFileExists{/System/Library/Fonts/Menlo.ttc}{
    \custsetup{system = mac}
  }{
    \IfFileExists{/dev/null}{
      \IfFileExists{null:}{
        \custsetup{system = windows}
      }{
        \custsetup{system = unix}
      }
    }{
      \custsetup{system = windows}
    }
  }
\fi

% 处理 \opt{fontset}
\ifcust@fontset@auto
  \ifcust@system@windows
    \custsetup{fontset = windows}
  \else
    \ifcust@system@mac
      \custsetup{fontset = mac}
    \else
      \IfFontExistsTF{Noto Serif CJK SC}{
        \custsetup{fontset = ubuntu}
      }{
        \custsetup{fontset = fandol}
      }
    \fi
  \fi
\fi

%学校论文撰写规范要求西文字体使用 Times New Roman 和 Arial，
% 但是在 Linux 下没有这两个字体，所以使用它们的克隆版 TeX Gyre Termes 和
% TeX Gyre Heros。
\ifcust@font@auto
  \ifcust@fontset@windows
    \custsetup{font=times}
  \else
    \ifcust@fontset@mac
      \custsetup{font=times}
    \else
      \custsetup{font=termes}
    \fi
  \fi
\fi

% Times New Roman + Arial
\newcommand\cust@set@font@times{%
  \setmainfont{Times New Roman}%
  \setsansfont{Arial}%
  \ifcust@system@mac
    \setmonofont{Menlo}[Scale = MatchLowercase]%
  \else
    \setmonofont{Courier New}[Scale = MatchLowercase]%
  \fi
}

% TeX Gyre Termes
\newcommand\cust@set@font@termes{%
  \setmainfont{texgyretermes}[
    Extension      = .otf,
    UprightFont    = *-regular,
    BoldFont       = *-bold,
    ItalicFont     = *-italic,
    BoldItalicFont = *-bolditalic,
  ]%
  \cust@set@texgyre@sans@mono
}

\newcommand\cust@set@texgyre@sans@mono{%
  \setsansfont{texgyreheros}[
    Extension      = .otf,
    UprightFont    = *-regular,
    BoldFont       = *-bold,
    ItalicFont     = *-italic,
    BoldItalicFont = *-bolditalic,
  ]%
  \setmonofont{texgyrecursor}[
    Extension      = .otf,
    UprightFont    = *-regular,
    BoldFont       = *-bold,
    ItalicFont     = *-italic,
    BoldItalicFont = *-bolditalic,
    Scale          = MatchLowercase,
    Ligatures      = CommonOff,
  ]%
}

% STIX Two 字体。
% STIX 文件名在 v2.10 2020-12-19 从
% \file{STIX2Text-Regular.otf}、\file{STIX2Math.otf} 分别改为
% \file{STIXTwoText-Regular.otf}、\file{STIXTwoMath-Regular.otf}。
\let\cust@font@family@stix\@empty
\newcommand\cust@set@stix@names{%
  \ifx\cust@font@family@stix\@empty
    \IfFontExistsTF{STIXTwoText-Regular.otf}{%
      \gdef\cust@font@family@stix{STIXTwoText}%
      \gdef\cust@font@name@stix@math{STIXTwoMath-Regular}%
    }{%
      \gdef\cust@font@family@stix{STIX2Text}%
      \gdef\cust@font@name@stix@math{STIX2Math}%
    }%
  \fi
}

\newcommand\cust@set@font@stix{%
  \cust@set@stix@names
  \setmainfont{\cust@font@family@stix}[
    Extension      = .otf,
    UprightFont    = *-Regular,
    BoldFont       = *-Bold,
    ItalicFont     = *-Italic,
    BoldItalicFont = *-BoldItalic,
  ]%
  \cust@set@texgyre@sans@mono
}

% XITS 字体。
% XITS 的文件名在 v1.109 2018-09-30
% 从 \file{xits-regular.otf}、\file{xits-math.otf} 分别改为
% \file{XITS-Regular.otf}、\file{XITSMath-Regular.otf}。
\let\cust@font@family@xits\@empty
\newcommand\cust@set@xits@names{%
  \ifx\cust@font@family@xits\@empty
    \IfFontExistsTF{XITSMath-Regular.otf}{%
      \gdef\cust@font@family@xits{XITS}%
      \gdef\cust@font@style@xits@rm{Regular}%
      \gdef\cust@font@style@xits@bf{Bold}%
      \gdef\cust@font@style@xits@it{Italic}%
      \gdef\cust@font@style@xits@bfit{BoldItalic}%
      \gdef\cust@font@name@xits@math{XITSMath-Regular}%
    }{%
      \gdef\cust@font@family@xits{xits}%
      \gdef\cust@font@style@xits@rm{regular}%
      \gdef\cust@font@style@xits@bf{bold}%
      \gdef\cust@font@style@xits@it{italic}%
      \gdef\cust@font@style@xits@bfit{bolditalic}%
      \gdef\cust@font@name@xits@math{xits-math}%
    }%
  \fi
}

\newcommand\cust@set@font@xits{%
  \cust@set@xits@names
  \setmainfont{\cust@font@family@xits}[
    Extension      = .otf,
    UprightFont    = *-\cust@font@style@xits@rm,
    BoldFont       = *-\cust@font@style@xits@bf,
    ItalicFont     = *-\cust@font@style@xits@it,
    BoldItalicFont = *-\cust@font@style@xits@bfit,
  ]%
  \cust@set@texgyre@sans@mono
}

% Libertinus 的文件名在 v6.7 2019-04-03 从小写改为驼峰式，
% 在大小写敏感的平台上需要进行判断。
\let\cust@font@family@libertinus\@empty
\newcommand\cust@set@libertinus@names{%
  \ifx\cust@font@family@libertinus\@empty
    \IfFontExistsTF{LibertinusSerif-Regular.otf}{%
      \gdef\cust@font@family@libertinus@serif{LibertinusSerif}%
      \gdef\cust@font@family@libertinus@sans{LibertinusSans}%
      \gdef\cust@font@name@libertinus@math{LibertinusMath-Regular}%
      \gdef\cust@font@style@libertinus@rm{Regular}%
      \gdef\cust@font@style@libertinus@bf{Bold}%
      \gdef\cust@font@style@libertinus@it{Italic}%
      \gdef\cust@font@style@libertinus@bfit{BoldItalic}%
    }{%
      \gdef\cust@font@family@libertinus@serif{libertinusserif}%
      \gdef\cust@font@family@libertinus@sans{libertinussans}%
      \gdef\cust@font@name@libertinus@math{libertinusmath-regular}%
      \gdef\cust@font@style@libertinus@rm{regular}%
      \gdef\cust@font@style@libertinus@bf{bold}%
      \gdef\cust@font@style@libertinus@it{italic}%
      \gdef\cust@font@style@libertinus@bfit{bolditalic}%
    }%
  \fi
}

\newcommand\cust@set@font@libertinus{%
  \cust@set@libertinus@names
  \setmainfont{\cust@font@family@libertinus@serif}[
    Extension      = .otf,
    UprightFont    = *-\cust@font@style@libertinus@rm,
    BoldFont       = *-\cust@font@style@libertinus@bf,
    ItalicFont     = *-\cust@font@style@libertinus@it,
    BoldItalicFont = *-\cust@font@style@libertinus@bfit,
  ]%
  \setsansfont{\cust@font@family@libertinus@sans}[
    Extension      = .otf,
    UprightFont    = *-\cust@font@style@libertinus@rm,
    BoldFont       = *-\cust@font@style@libertinus@bf,
    ItalicFont     = *-\cust@font@style@libertinus@it,
  ]%
  \setmonofont{lmmonolt10}[
    Extension      = .otf,
    UprightFont    = *-regular,
    BoldFont       = *-bold,
    ItalicFont     = *-oblique,
    BoldItalicFont = *-boldoblique,
  ]%
}

% New Computer Modern
\newcommand\cust@set@font@newcm{%
  \setmainfont{NewCM10}[
    Extension      = .otf,
    UprightFont    = *-Book,
    BoldFont       = *-Bold,
    ItalicFont     = *-BookItalic,
    BoldItalicFont = *-BoldItalic,
  ]%
  \setsansfont{NewCMSans10}[
    Extension         = .otf,
    UprightFont       = *-Book,
    BoldFont          = *-Bold,
    ItalicFont        = *-BookOblique,
    BoldItalicFont    = *-BoldOblique,
  ]%
  \setmonofont{NewCMMono10}[
    Extension           = .otf,
    UprightFont         = *-Book,
    ItalicFont          = *-BookItalic,
    BoldFont            = *-Bold,
    BoldItalicFont      = *-BoldOblique,
  ]%
}

% Latin Modern
\newcommand\cust@set@font@lm{%
  \setmainfont{lmroman10}[
    Extension      = .otf,
    UprightFont    = *-regular,
    BoldFont       = *-bold,
    ItalicFont     = *-italic,
    BoldItalicFont = *-bolditalic,
  ]%
  \setsansfont{lmsans10}[
    Extension      = .otf,
    UprightFont    = *-regular,
    BoldFont       = *-bold,
    ItalicFont     = *-oblique,
    BoldItalicFont = *-boldoblique,
  ]%
  \setmonofont{lmmonolt10}[
    Extension      = .otf,
    UprightFont    = *-regular,
    BoldFont       = *-bold,
    ItalicFont     = *-oblique,
    BoldItalicFont = *-boldoblique,
  ]%
}

\newcommand\cust@set@font@newtx{%
  \RequirePackage{newtxtext}%
}

\newcommand\cust@set@font{%
  \@nameuse{cust@set@font@\cust@font}%
}
\cust@set@font
\cust@option@hook{font}{\cust@set@font}

% 中文字体
\ifcust@cjk@font@auto
  \ifcust@fontset@mac
    \custsetup{cjk-font = mac}
  \else
    \ifcust@fontset@windows
      \custsetup{cjk-font = windows}
    \else
      \ifcust@fontset@ubuntu
        \custsetup{cjk-font = noto}
      \else
        \custsetup{cjk-font = fandol}
      \fi
    \fi
  \fi
\fi

% Windows 的中易字体。
\newcommand\cust@set@cjk@font@windows{%
  \setCJKmainfont{SimSun}[
    AutoFakeBold = 3,
    ItalicFont   = KaiTi,
  ]%
  \setCJKsansfont{SimHei}[AutoFakeBold = 3]%
  \setCJKmonofont{FangSong}%
  \setCJKfamilyfont{zhsong}{SimSun}[AutoFakeBold = 3]%
  \setCJKfamilyfont{zhhei}{SimHei}[AutoFakeBold = 3]%
  \setCJKfamilyfont{zhkai}{KaiTi}%
  \setCJKfamilyfont{zhfs}{FangSong}%
}

% macOS 的华文字体。
\newcommand\cust@set@cjk@font@mac{%
  \defaultCJKfontfeatures{}%
  \setCJKmainfont{Songti SC}[
    UprightFont    = * Light,
    BoldFont       = * Bold,
    ItalicFont     = Kaiti SC Regular,
    BoldItalicFont = Kaiti SC Bold,
  ]%
  \setCJKsansfont{Heiti SC}[
    UprightFont    = * Light,
    BoldFont       = * Medium,
  ]%
  \setCJKmonofont{STFangsong}
  \setCJKfamilyfont{zhsong}{Songti SC}[
    UprightFont    = * Light,
    BoldFont       = * Bold,
  ]%
  \setCJKfamilyfont{zhhei}{Heiti SC}[
    UprightFont    = * Light,
    BoldFont       = * Medium,
  ]%
  \setCJKfamilyfont{zhfs}{STFangsong}%
  \setCJKfamilyfont{zhkai}{Kaiti SC}[
    UprightFont    = * Regular,
    BoldFont       = * Bold,
  ]%
  \setCJKfamilyfont{zhli}{Baoli SC}%
  \setCJKfamilyfont{zhyuan}{Yuanyi SC}[
    UprightFont    = * Light,
    BoldFont       = * Bold,
  ]%
}

% 思源字体。
% 注意 Noto CJK 的 regular 字重名字不带“Regular”。
\newcommand\cust@set@cjk@font@noto{%
  \defaultCJKfontfeatures{}%
  \setCJKmainfont{Noto Serif CJK SC}[
    UprightFont    = * Light,
    BoldFont       = * Bold,
    ItalicFont     = FandolKai-Regular,
    ItalicFeatures = {Extension = .otf},
    Script         = CJK,
  ]%
  \setCJKsansfont{Noto Sans CJK SC}[
    BoldFont       = * Medium,
    Script         = CJK,
  ]%
  \setCJKmonofont{Noto Sans Mono CJK SC}[
    Script         = CJK,
  ]%
  \setCJKfamilyfont{zhsong}{Noto Serif CJK SC}[
    UprightFont    = * Light,
    UprightFont    = * Bold,
    Script         = CJK,
  ]%
  \setCJKfamilyfont{zhhei}{Noto Sans CJK SC}[
    BoldFont       = * Medium,
    Script         = CJK,
  ]%
  \setCJKfamilyfont{zhfs}{FandolFang}[
    Extension      = .otf,
    UprightFont    = *-Regular,
  ]%
  \setCJKfamilyfont{zhkai}{FandolKai}[
    Extension      = .otf,
    UprightFont    = *-Regular,
  ]%
}

% Fandol 字体。
\newcommand\cust@set@cjk@font@fandol{%
  \defaultCJKfontfeatures{}%
  \setCJKmainfont{FandolSong}[
    Extension   = .otf,
    UprightFont = *-Regular,
    BoldFont    = *-Bold,
    ItalicFont  = FandolKai-Regular,
    ItalicFeatures = {Extension = .otf},
  ]%
  \setCJKsansfont{FandolHei}[
    Extension   = .otf,
    UprightFont = *-Regular,
    BoldFont    = *-Bold,
  ]%
  \setCJKmonofont{FandolFang}[
    Extension   = .otf,
    UprightFont = *-Regular,
  ]%
  \setCJKfamilyfont{zhsong}{FandolSong}[
    Extension   = .otf,
    UprightFont = *-Regular,
    BoldFont    = *-Bold,
  ]%
  \setCJKfamilyfont{zhhei}{FandolHei}[
    Extension   = .otf,
    UprightFont = *-Regular,
    BoldFont    = *-Bold,
  ]%
  \setCJKfamilyfont{zhfs}{FandolFang}[
    Extension   = .otf,
    UprightFont = *-Regular,
  ]%
  \setCJKfamilyfont{zhkai}{FandolKai}[
    Extension   = .otf,
    UprightFont = *-Regular,
  ]%
}

\ifcust@cjk@font@none\else
  \providecommand\songti{\CJKfamily{zhsong}}
  \providecommand\heiti{\CJKfamily{zhhei}}
  \providecommand\fangsong{\CJKfamily{zhfs}}
  \providecommand\kaishu{\CJKfamily{zhkai}}
\fi

\newcommand\cust@set@cjk@font{%
  \@nameuse{cust@set@cjk@font@\cust@cjk@font}%
}
\cust@set@cjk@font
\cust@option@hook{cjk-font}{\cust@set@cjk@font}

% 数学字体

%设置公式编号格式
%默认的公式编号格式为1.1，按照《规范》要求，应修改成1-1
%按二级节标题编号,如 1.1-1
%\renewcommand\thesubsection{\thesection-\arabic{equation}}
%按章编号
\renewcommand\theequation{\thechapter-\arabic{equation}}

% 设置数学符号风格。
\newcommand\cust@set@math@style{%
  \ifcust@math@style@TeX
    \custsetup{
      uppercase-greek    = upright,
      less-than-or-equal = horizontal,
      integral           = slanted,
      integral-limits    = false,
      partial            = italic,
      math-ellipsis      = AMS,
      real-part          = fraktur,
    }%
  \else
    \custsetup{
      uppercase-greek = italic,
      integral        = upright,
      partial         = upright,
      real-part       = roman,
    }%
    \ifcust@math@style@ISO
      \custsetup{
        less-than-or-equal = horizontal,
        integral-limits    = true,
        math-ellipsis      = lower,
      }%
    \else
      \ifcust@math@style@GB
        \custsetup{
          less-than-or-equal = slanted,
          integral-limits    = false,
          math-ellipsis      = centered,
        }%
      \fi
    \fi
  \fi
}

\ifcust@main@language@chinese
  \custsetup{math-style = GB}%
\else
  \custsetup{math-style = TeX}%
\fi

\cust@set@math@style
\cust@option@hook{math-style}{\cust@set@math@style}
\cust@option@hook{main-language}{%
  \ifcust@main@language@chinese
    \custsetup{math-style = GB}%
  \else
    \custsetup{math-style = TeX}%
  \fi
}

% 针对 \pkg{unicode-math} 逐项配置数学符号。

\newcommand\cust@set@unimath@leq{%
  \ifcust@leq@horizontal
    \ifx\@begindocumenthook\@undefined
      \let\le\cust@save@leq
      \let\ge\cust@save@geq
      \let\leq\cust@save@leq
      \let\geq\cust@save@geq
    \else
      \AtBeginDocument{%
        \let\le\cust@save@leq
        \let\ge\cust@save@geq
        \let\leq\cust@save@leq
        \let\geq\cust@save@geq
      }%
    \fi
  \else
    \ifcust@leq@slanted
      \ifx\@begindocumenthook\@undefined
        \let\le\leqslant
        \let\ge\geqslant
        \let\leq\leqslant
        \let\geq\geqslant
      \else
        \AtBeginDocument{%
          \let\le\leqslant
          \let\ge\geqslant
          \let\leq\leqslant
          \let\geq\geqslant
        }%
      \fi
    \fi
  \fi
}
\newcommand\cust@set@unimath@integral@limits{%
  \ifcust@integral@limits@true
    \removenolimits{%
      \int\iint\iiint\iiiint\oint\oiint\oiiint
      \intclockwise\varointclockwise\ointctrclockwise\sumint
      \intbar\intBar\fint\cirfnint\awint\rppolint
      \scpolint\npolint\pointint\sqint\intlarhk\intx
      \intcap\intcup\upint\lowint
    }%
  \else
    \addnolimits{%
      \int\iint\iiint\iiiint\oint\oiint\oiiint
      \intclockwise\varointclockwise\ointctrclockwise\sumint
      \intbar\intBar\fint\cirfnint\awint\rppolint
      \scpolint\npolint\pointint\sqint\intlarhk\intx
      \intcap\intcup\upint\lowint
    }%
  \fi
}
\newcommand\cust@set@unimath@ellipsis{%
  \ifcust@math@ellipsis@centered
    \DeclareRobustCommand\mathellipsis{\mathinner{\unicodecdots}}%
  \else
    \DeclareRobustCommand\mathellipsis{\mathinner{\unicodeellipsis}}%
  \fi
}
\newcommand\cust@set@unimath@real@part{%
  \ifcust@real@part@roman
    \AtBeginDocument{%
      \def\Re{\operatorname{Re}}%
      \def\Im{\operatorname{Im}}%
    }%
  \else
    \AtBeginDocument{%
      \let\Re\cust@save@Re
      \let\Im\cust@save@Im
    }%
  \fi
}

\newcommand\cust@set@unimath@style{%
  \ifcust@uppercase@greek@upright
    \unimathsetup{math-style = TeX}%
  \else
    \ifcust@uppercase@greek@italic
      \unimathsetup{math-style = ISO}%
    \fi
  \fi
  \ifcust@math@style@TeX
    \unimathsetup{bold-style = TeX}%
  \else
    \unimathsetup{bold-style = ISO}%
  \fi
  \cust@set@unimath@leq
  \cust@set@unimath@integral@limits
  \ifcust@partial@upright
    \unimathsetup{partial = upright}%
  \else
    \ifcust@partial@italic
      \unimathsetup{partial = italic}%
    \fi
  \fi
  \cust@set@unimath@ellipsis
  \cust@set@unimath@real@part
}

\newcommand\cust@qed{\rule{1ex}{1ex}}
\newcommand\cust@load@unimath{%
  \@ifpackageloaded{unicode-math}{}{%
    \RequirePackage{unicode-math}%
    \AtBeginDocument{%
      \let\cust@save@leq\leq
      \let\cust@save@geq\geq
      \let\cust@save@Re\Re
      \let\cust@save@Im\Im
    }%
    %
    % 兼容旧的粗体命令：\pkg{bm} 的 \cs{bm} 和 \pkg{amsmath} 的 \cs{boldsymbol}。
    \DeclareRobustCommand\bm[1]{{\symbfit{##1}}}%
    \DeclareRobustCommand\boldsymbol[1]{{\symbfit{##1}}}%
    %
    % 兼容 \pkg{amsfonts} 和 \pkg{amssymb} 中的一些命令。
    \newcommand\square{\mdlgwhtsquare}%
    \newcommand\blacksquare{\mdlgblksquare}%
    \AtBeginDocument{%
      \renewcommand\checkmark{\ensuremath{✓}}%
    }%
    %
    % 兼容 \pkg{amsthm} 的 \cs{qedsymbol}。
    \renewcommand\cust@qed{\ensuremath{\QED}}%
  }%
}

% STIX Two Math
\newcommand\cust@set@math@font@stix{%
  \cust@load@unimath
  \cust@set@unimath@style
  \cust@set@stix@names
  \setmathfont{\cust@font@name@stix@math}[
    Extension    = .otf,
    Scale        = MatchLowercase,
    StylisticSet = \cust@xits@integral@stylistic@set,
  ]%
  \setmathfont{\cust@font@name@stix@math}[
    Extension    = .otf,
    Scale        = MatchLowercase,
    StylisticSet = 1,
    range        = {scr,bfscr},
  ]%
}

% XITS Math
\newcommand\cust@xits@integral@stylistic@set{%
  \ifcust@integral@upright
    8%
  \fi
}
\newcommand\cust@set@math@font@xits{%
  \cust@load@unimath
  \cust@set@unimath@style
  \cust@set@xits@names
  \setmathfont{\cust@font@name@xits@math}[
    Extension    = .otf,
    StylisticSet = \cust@xits@integral@stylistic@set,
  ]%
  \setmathfont{\cust@font@name@xits@math}[
    Extension    = .otf,
    StylisticSet = 1,
    range        = {cal,bfcal},
  ]%
}

% Libertinus Math
\newcommand\cust@libertinus@integral@stylistic@set{%
  \ifcust@integral@slanted
    8%
  \fi
}
\newcommand\cust@set@math@font@libertinus{%
  \cust@load@unimath
  \cust@set@unimath@style
  \cust@set@libertinus@names
  \cust@set@xits@names
  \setmathfont{\cust@font@name@libertinus@math}[
    Extension    = .otf,
    StylisticSet = \cust@libertinus@integral@stylistic@set,
  ]%
  \setmathfont{\cust@font@name@xits@math}[
    Extension    = .otf,
    range        = {\checkmark},
  ]%
}

% New Computer Modern Math
\newcommand\cust@newcm@integral@stylistic@set{%
  \ifcust@integral@upright
    2%
  \fi
}
\newcommand\cust@set@math@font@newcm{%
  \cust@load@unimath
  \cust@set@unimath@style
  \setmathfont{NewCMMath-Book}[
    Extension    = .otf,
    StylisticSet = \cust@newcm@integral@stylistic@set,
  ]%
  \setmathfont{NewCMMath-Book}[
    Extension    = .otf,
    StylisticSet = 1,
    range        = {scr,bfscr},
  ]%
  \setmathrm{NewCM10}[
    Extension      = .otf,
    UprightFont    = *-Book,
    BoldFont       = *-Bold,
    ItalicFont     = *-BookItalic,
    BoldItalicFont = *-BoldItalic,
  ]%
  \setmathsf{NewCMSans10}[
    Extension         = .otf,
    UprightFont       = *-Book,
    BoldFont          = *-Bold,
    ItalicFont        = *-BookOblique,
    BoldItalicFont    = *-BoldOblique,
  ]%
  \setmathtt{NewCMMono10}[
    Extension           = .otf,
    UprightFont         = *-Book,
    ItalicFont          = *-BookItalic,
    BoldFont            = *-Bold,
    BoldItalicFont      = *-BoldOblique,
  ]%
}

% Latin Modern Math
\newcommand\cust@set@math@font@lm{%
  \cust@load@unimath
  \cust@set@unimath@style
  \setmathfont{latinmodern-math}[Extension=.otf]%
  \setmathrm{lmroman10}[
    Extension      = .otf,
    UprightFont    = *-regular,
    BoldFont       = *-bold,
    ItalicFont     = *-italic,
    BoldItalicFont = *-bolditalic,
  ]%
  \setmathsf{lmsans10}[
    Extension      = .otf,
    UprightFont    = *-regular,
    BoldFont       = *-bold,
    ItalicFont     = *-oblique,
    BoldItalicFont = *-boldoblique,
  ]%
  \setmathtt{lmmonolt10}[
    Extension      = .otf,
    UprightFont    = *-regular,
    BoldFont       = *-bold,
    ItalicFont     = *-oblique,
    BoldItalicFont = *-boldoblique,
  ]%
}

% NewTX Math
% 注意 NewTX Math 是 Type 1 字体，如果正文西文使用了 OpenType 字体时需要小心处理。
\newcommand\cust@set@math@font@newtx{%
  \ifcust@font@newtx\else
    \let\cust@save@encodingdefault\encodingdefault
    \let\cust@save@rmdefault\rmdefault
    \let\cust@save@sfdefault\sfdefault
    \let\cust@save@ttdefault\ttdefault
    \RequirePackage[T1]{fontenc}%
    \renewcommand{\rmdefault}{ntxtlf}%
    \renewcommand{\sfdefault}{qhv}%
    \renewcommand{\ttdefault}{ntxtt}%
  \fi
  \ifcust@uppercase@greek@italic
    \PassOptionsToPackage{slantedGreek}{newtxmath}%
  \fi
  \ifcust@integral@upright
    \PassOptionsToPackage{upint}{newtxmath}%
  \fi
  \RequirePackage{newtxmath}
  \let\cust@save@leq\leq
  \let\cust@save@geq\geq
  \ifcust@leq@slanted
    \let\le\leqslant
    \let\ge\geqslant
    \let\leq\leqslant
    \let\geq\geqslant
  \fi
  \ifcust@integral@limits@true
    \let\ilimits@\displaylimits
  \fi
  \let\cust@save@partial\partial
  \ifcust@partial@upright
    \let\partial\uppartial
  \fi
  \ifcust@math@ellipsis@centered
    \DeclareRobustCommand\mathellipsis{\mathinner{\cdotp\cdotp\cdotp}}%
  \else
    \DeclareRobustCommand\mathellipsis{\mathinner{\ldotp\ldotp\ldotp}}%
  \fi
  \let\cust@save@Re\Re
  \let\cust@save@Im\Im
  \ifcust@real@part@roman
    \def\Re{\operatorname{Re}}%
    \def\Im{\operatorname{Im}}%
  \fi
  \RequirePackage{bm}%
  \ifcust@font@newtx\else
    \let\encodingdefault\cust@save@encodingdefault
    \let\rmdefault\cust@save@rmdefault
    \let\sfdefault\cust@save@sfdefault
    \let\ttdefault\cust@save@ttdefault
  \fi
  \DeclareRobustCommand\symup[1]{{\mathrm{##1}}}%
  \DeclareRobustCommand\symbf[1]{{\bm{##1}}}%
  \DeclareRobustCommand\symbfsf[1]{{\bm{##1}}}%
  \let\increment\upDelta%
  \renewcommand\cust@qed{\openbox}%
}

% Computer Modern
% 使用 LaTeX 默认的 cm 字体
\newcommand\cust@set@math@font@cm{%
  \RequirePackage{amssymb}
  \let\cust@save@leq\leq
  \let\cust@save@geq\geq
  \ifcust@leq@slanted
    \let\le\leqslant
    \let\ge\geqslant
    \let\leq\leqslant
    \let\geq\geqslant
  \fi
  \ifcust@integral@limits@true
    \let\ilimits@\displaylimits
  \fi
  \ifcust@math@ellipsis@centered
    \DeclareRobustCommand\mathellipsis{\mathinner{\cdotp\cdotp\cdotp}}%
  \else
    \DeclareRobustCommand\mathellipsis{\mathinner{\ldotp\ldotp\ldotp}}%
  \fi
  \let\cust@save@Re\Re
  \let\cust@save@Im\Im
  \ifcust@real@part@roman
    \def\Re{\operatorname{Re}}%
    \def\Im{\operatorname{Im}}%
  \fi
  \RequirePackage{bm}%
  \DeclareRobustCommand\symup[1]{{\mathrm{##1}}}%
  \DeclareRobustCommand\symbf[1]{{\bm{##1}}}%
  \DeclareRobustCommand\symbfsf[1]{{\bm{##1}}}%
  \let\increment\Delta
  \renewcommand\cust@qed{\openbox}%
  \let\uppi\pi
}

% 不设置数学字体，仅提供兼容支持。
\newcommand\cust@set@math@font@none{%
  \RequirePackage{amssymb}
  \RequirePackage{bm}%
  \DeclareRobustCommand\symup[1]{{\mathrm{##1}}}%
  \DeclareRobustCommand\symbf[1]{{\bm{##1}}}%
  \DeclareRobustCommand\symbfsf[1]{{\bm{##1}}}%
  \let\increment\Delta
  \renewcommand\cust@qed{\openbox}%
  \let\uppi\pi
}

\newcommand\cust@set@math@font{%
  \@nameuse{cust@set@math@font@\cust@math@font}%
}
\cust@option@hook{math-font}{\g@addto@macro\cust@setup@hook{\cust@set@math@font}}
\newcommand\cust@set@math@font@auto{%
  \ifcust@math@font@auto
    \custsetup{math-font=xits}%
  \fi
}
\AtBeginOfPackageFile*{siunitx}{\cust@set@math@font@auto}
\AtEndPreamble{%
  \cust@set@math@font@auto
  \ifx\square\@undefined
    \RequirePackage{amssymb}%
  \fi
}



% \subsection{纸张和页面}
% 使用 \pkg{geometry} 宏包设置纸张和页面。

% 纸张：A4；

% 页面设置：上3.5cm、下 2.5 cm，左、右 2.7 cm，页眉 2.5 cm，页脚 1.8 cm。

% 注意这里指的是页眉顶部到纸张顶部的距离为 2.5 cm，
% 3.5-headheight-headsep=3.5-0.75-0.25 =2.5cm
% 注意这里指的是页脚底部部到纸张底部的距离为 1.8 cm
% 2.5-footskip=2.5-0.7=1.8cm
%vmargin    = 2.5cm,
\geometry{
  paper      = a4paper,
  top        = 3.5cm,
  bottom     = 2.5cm,
  hmargin    = 2.7cm,
  headheight = 0.75cm,
  headsep    = 0.25cm,
  footskip   = 0.7cm,
}

% 使用 \pkg{fancy} 需要先调用 |\pagestyle{fancy}| 再修改 \cs{chaptermark} 和
% \cs{sectionmark}。
\pagestyle{fancy}
\let\sectionmark\@gobble
\renewcommand\headrulewidth{0.4\p@}

% 重定义默认的 |plain| page style，会显示页眉和页脚。
\fancypagestyle{plain}{%
  \fancyhf{}%
  %
  % 页眉与该部分的章标题相同，宋体 10.5 磅（五号字）居中。
  % 页码：宋体 10.5 磅、页面下脚居中。
  \ifcust@degree@graduate
    \def\cust@hf@font{\fontsize{10.5bp}{12bp}\selectfont}
    \fancyhead[C]{\cust@hf@font\leftmark}%
    \fancyfoot[C]{\cust@hf@font\thepage}%
    \let\@mkboth\markboth
    \def\chaptermark##1{%
      \markboth{\CTEXifname{\CTEXthechapter\quad}{}\cust@spacetitle{##1}}{}%
    }%
    \let\sectionmark\@gobble
  \else
    %
    % 本科生要求除封面、扉页外，每面上部加页眉，
    % 用宋体10.5磅（五号字）标注“长春理工大学本科生毕业论文或长春理工大学本科生毕业设计”，居中；
    % 从目录页开始在每面底部居中用宋体10.5磅（五号字）连续编页码。
    \def\cust@hf@font{\fontsize{10.5bp}{12bp}\selectfont}
    \fancyhead[C]{\cust@hf@font 长春理工大学\cust@thesis@name}%
    \fancyfoot[C]{\cust@hf@font\thepage}%
    \let\@mkboth\@gobbletwo
    \let\chaptermark\@gobble
    \let\sectionmark\@gobble
  \fi
}
\pagestyle{plain}

% |headings| 只有页眉，没有页脚，用于研究生的符号说明和本科生的 front matter。
\fancypagestyle{headings}{\fancyfoot{}}

% 设置特殊的 page style 不改变任何内容，用于每章首页。
\def\ps@chapter{}
\ctexset{chapter/pagestyle=chapter}

% 空白页不加页眉和页码。
\def\cleardoublepage{%
  \clearpage
  \if@twoside
    \ifodd\c@page\else
      \hbox{}%
%      \ifcust@degree@graduate
        \thispagestyle{empty}%
%      \fi
      \newpage
      \if@twocolumn
        \hbox{}%
        \newpage
      \fi
    \fi
  \fi
}

%
% 《规范》要求，从摘要开始编页码，
% 而且中英文摘要，目录均独立编页码
\renewcommand\frontmatter{%
  \cleardoublepage%生成空白页
  \@mainmatterfalse
  \pagenumbering{Roman}%
  \pagestyle{plain}%
}

%% 研究生要求“第 1 章”要另页起，但是本科生要求另面起。
%\renewcommand\mainmatter{%
%  \cleardoublepage
%  \ifcust@degree@graduate
%    \pagenumbering{arabic}%
%  \fi
%  \pagestyle{plain}%
%  \@mainmattertrue
%}
% 《规范》要求正文以后用阿拉伯数字编码，相当于从“第 1 章”要另页起。
\renewcommand\mainmatter{%
  \cleardoublepage
    \pagenumbering{arabic}%
  \pagestyle{plain}%
  \@mainmattertrue
}

\g@addto@macro\appendix{\@mainmattertrue}%


% \subsection{封面}


% 定义用户接口：
\cust@define@key{
  title = {
    default = {论文题目},
  },
  title* = {
    default = {Title},
    name    = title@en,
  },
  author = {
    default = {研究生},
  },
  author* = {
    default = {Author Name},
    name    = author@en,
  },
  speciality = {
    default = {专业},
  },
  speciality* = {
    default = {Speciality},
    name    = speciality@en,
  },
  supervisor = {
    default = {指导教师},
  },
  supervisor* = {
    default = {Supervisor Name},
    name    = supervisor@en,
  },
  advisor = {
    default = {},
  },
  advisor* = {
    default = {},
    name    = advisor@en,
  },
  date = {
    default = {\the\year-\two@digits{\month}-\two@digits{\day}},
  },
  start-date ={
    name = start@date
  },
  professional-type = {
    name = professional@type,
  },
  professional-type* = {
    name = professional@type@en,
  },
  degree-area* = {
    name = degree@area@en,
  },
  department={
    name = department,
  },
  student-id = {
    name = student@id,
  },
  secret-level = {
    name    = secret@level,
  },
  secret-level* = {
    name    = secret@level@en,
  },
  secret-year = {
    name    = secret@year,
  },
  keywords,
  keywords* = {
    name    = keywords@en,
  },
}

% 导师一栏可能有多个姓名，所以用 \opt{supervisor} 进行收集，
% 然后使用本命令来输出要求的格式，
% 类似于 \LaTeX3 的 \cs{clist\_use:Nn}。
\newcommand\cust@clist@count[1]{%
  \csname clist_count:N\endcsname{#1}%
}
\newcommand\cust@clist@use[2]{%
  \csname clist_use:Nn\endcsname{#1}{#2}%
}
\newcommand\cust@supervisor@names{%
  \cust@clist@use{\cust@supervisor}{\quad}
}
\newcommand\cust@advisor@names{%
  \cust@clist@use{\cust@advisor}{\quad}
}
\newcounter{cust@count}
\newcommand\cust@supervisor@en@line{%
  \setcounter{cust@count}{\cust@clist@count{\cust@supervisor@en}}%
  \ifnum\c@cust@count>1\relax
    Supervisors:\\%
  \else
    Supervisor:\\%
  \fi
  \space\cust@clist@use{\cust@supervisor@en}{, }%
}
\newcommand\cust@advisor@en@line{%
  \setcounter{cust@count}{\cust@clist@count{\cust@advisor@en}}%
  \ifnum\c@cust@count>1\relax
    Advisor:%
  \else
    Advisor:%
  \fi
  \space\cust@clist@use{\cust@advisor@en}{, }%
}

% 输出日期的给定格式：\cs{cust@format@date}\marg{format}\marg{date}，
% 其中格式 \meta{format} 接受三个参数分别对应年、月、日，
% \meta{date} 是 ISO 格式的日期（yyyy-mm-dd）。
\newcommand\cust@format@date[2]{%
  \edef\cust@@date{#2}%
  \def\cust@@process@date##1-##2-##3\@nil{%
    #1{##1}{##2}{##3}%
  }%
  \expandafter\cust@@process@date\cust@@date\@nil
}
\newcommand\cust@date@format@zh@small[3]{\number#1 年 \number#2 月 \number#3 日}
\newcommand\cust@date@format@zh@big[3]{\zhdigits{#1}年\zhnumber{#2}月\zhnumber{#3}日}
\newcommand\cust@date@format@zh@shortbig[3]{\zhdigits{#1}年\zhnumber{#2}月}
\newcommand\cust@date@month[1]{%
  \ifcase\number#1\or
    January\or February\or March\or April\or May\or June\or
    July\or August\or September\or October\or November\or December%
  \fi
}
\newcommand\cust@date@format@zh@short[3]{\number#1 年 \number#2 月}
\newcommand\cust@date@format@en[3]{\cust@date@month{#2} \number#3, #1}
\newcommand\cust@date@format@en@short[3]{\cust@date@month{#2} \number#1}
\newcommand\cust@date@zh@small{\cust@format@date{\cust@date@format@zh@small}{\cust@date}}
\newcommand\cust@date@zh@big{\cust@format@date{\cust@date@format@zh@big}{\cust@date}}
\newcommand\cust@date@zh@short{\cust@format@date{\cust@date@format@zh@short}{\cust@date}}
\newcommand\cust@date@en{\cust@format@date{\cust@date@format@en}{\cust@date}}
\newcommand\cust@date@en@short{\cust@format@date{\cust@date@format@en@short}{\cust@date}}
\newcommand\cust@date@zh@shortbig{\cust@format@date{\cust@date@format@zh@shortbig}{\cust@date}}


% 版本 v3.2 开始使用 \cs{custsetup} 设置接口，
% 兼容旧版本的命令式设置。
% Reserved for compatibility until 2020-07-01.
\def\cust@define@term#1#2{%
  \expandafter\gdef\csname #1\endcsname##1{%
    \custsetup{#2 = {##1}}%
  }%
}
\cust@define@term{title}{title}
\cust@define@term{entitle}{title*}
\cust@define@term{author}{author}
\cust@define@term{enauthor}{author*}
\cust@define@term{major}{speciality}
\cust@define@term{enmajor}{speciality*}
\cust@define@term{supervisor}{supervisor}
\cust@define@term{ensupervisor}{supervisor*}
\gdef\cosupervisor#1{%
  \g@addto@macro\cust@supervisor{, #1}%
}
\gdef\encosupervisor#1{%
  \g@addto@macro\cust@supervisor@en{, #1}%
}
\gdef\date#1{\renewcommand\cust@date@zh@big{#1}}
\gdef\endate#1{\renewcommand\cust@date@en{#1}}
\cust@define@term{professionaltype}{professional-type}
\cust@define@term{enprofessionaltype}{professional-type*}
\cust@define@term{secretlevel}{secret-level}
\cust@define@term{ensecretlevel}{secret-level*}
\cust@define@term{secretyear}{secret-year}
\gdef\keywords#1{\renewcommand\cust@keywords@text{#1}}
\gdef\enkeywords#1{\renewcommand\cust@keywords@en@text{#1}}

% 定义一些常量。
\ifcust@degree@doctor
  \newcommand\cust@thesis@name{博士学位(毕业)论文}
  \newcommand\cust@thesis@name@en{Doctor of Philosophy}
\else
  \ifcust@degree@master
    \newcommand\cust@thesis@name{硕士学位(毕业)论文}
    \newcommand\cust@thesis@name@en{A dissertation for master's degree}
  \else
    \newcommand\cust@thesis@name{本科生毕业论文}
    \newcommand\cust@thesis@name@en{A dissertation for bachelor's degree}
  \fi
\fi
\ifcust@degree@type@academic
  \newcommand\cust@speciality@name{学\hspace{0.3cm}科\hspace{0.3cm}专\hspace{0.3cm}业}
\else
  \ifcust@degree@doctor
    \renewcommand\cust@thesis@name{专业博士学位论文}
  \else
    \ifcust@degree@master
        \renewcommand\cust@thesis@name{硕士学位(毕业)论文}
    \else
        \renewcommand\cust@thesis@name{本科生毕业设计}
    \fi
  \fi
  \ifcust@cjk@font@mac
    \providecommand\lishu{\CJKfamily{zhli}}
  \else
    \ifcust@cjk@font@windows
      \setCJKfamilyfont{zhli}{LiSu}
      \providecommand\lishu{\CJKfamily{zhli}}
    \else
      \cust@warning{LiShu font is required}
      \providecommand\lishu{\sffamily}
    \fi
  \fi
  \newcommand\cust@speciality@name{类\hpace{0.3cm}别\hspace{0.3cm}领\hspace{0.3cm}域}
\fi
%定义原创性声明文字中的硕士、博士层次等常量。
\ifcust@degree@doctor
   \newcommand\cust@thesis@level{博士}
\else
    \ifcust@degree@master
        \newcommand\cust@thesis@level{硕士}
    \else
        \newcommand\cust@thesis@level{学士}
    \fi
\fi
% 定义校徽颜色
%
% 推迟定义颜色以避免调用 \pkg{xcolor} 时的警告
\AtBeginDocument{
  \definecolor{custblue}{cmyk}{1,0.8,0,0}
}

% 添加 PDF 书签，在 \pkg{hyperref} 载入后才有效。
\newcommand\cust@pdfbookmark{\@gobble}

% 重定义 \env{titlepage} 环境，不修改页码。
\renewenvironment{titlepage}{%
  \cleardoublepage
  \if@twocolumn
    \@restonecoltrue\onecolumn
  \else
    \@restonecolfalse\newpage
  \fi
  \thispagestyle{empty}%
}{%
  \if@restonecol\twocolumn \else \newpage \fi
}

% 研究生（博士，硕士）中文封面：
% 密级黑体 12 磅；
% 论文类型宋体 44 磅加粗；
% 论文题目黑体二号 22 磅居中，1.25行距；
% 作者姓名、指导教师、学科专业，黑体三号、16 磅加粗，1.25行距；
% 注意这里的“1.25行距”的地方开启了“对齐到网格”，所以实际行距有所偏差，
% 所以只能使用直尺测量。
\newcommand\cust@speciality@sse{信息对抗技术}
\newcommand\cust@title@page@graduate@zh{%
  \custsetup{language=chinese}%
  \begin{titlepage}%
    \cust@pdfbookmark{封面}%
    \centering
    \parbox[t][0.5cm][t]{\textwidth}{%
      \raggedleft\sffamily\fontsize{12bp}{12bp}\selectfont
      \textsf{学号：}\cust@underline[3cm]{\cust@student@id}
      }\par
    \vskip 2.5cm%
    \includegraphics[height=3.1499cm]{figures/cust-name.pdf}\par
    \vskip 3.8866cm%bp:磅 此为图片和论文类型间距。
    {\rmfamily\fontsize{44bp}{21bp}\selectfont
      \cust@thesis@name}%\sffamily为无衬线字体
    \ifcust@degree@type@academic
      \vskip 0.1533cm%此为论文类型与论文题目间距
    \else
      \vskip 0.1533cm%
%      \begingroup%论文题目，22磅，黑体，1.25倍行距
%        \heiti\fontsize{22bp}{22bp}\selectfont
%        \ifx\cust@professional@type\@empty
%          \null
%        \else
%          \lishu （\cust@professional@type ）%
%        \fi
%%        \par
%      \endgroup
%%      \vskip 1.0cm%
    \fi
%    \vskip 0.4cm%
    %论文题目盒子，宽度为\textwidth
    \parbox[t][5.5cm][c]{\textwidth}{%
      \centering\sffamily\bfseries\fontsize{22bp}{30bp}\selectfont
      \cust@title\par}
%    \vskip 0.2cm%
    %作者信息
    \sffamily\bfseries\fontsize{16bp}{30bp}\selectfont
      \begin{tabular}{@{}l@{\hspace{\ccwd}}l@{}}%
        \textsf{研\hspace{0.7cm}究\hspace{0.7cm}生：} & \cust@author \\
        \textsf{\cust@speciality@name：} & \cust@speciality \\
%        \ifx\cust@advisor\@empty
          \textsf{指\hspace{0.3cm}导\hspace{0.3cm}教\hspace{0.3cm}师：} & \cust@supervisor@names \\
%        \else
%          \textsf{校内导师：} & \cust@supervisor@names \\
%          \textsf{企业行业导师：} & \cust@advisor@names \\
%        \fi
      \end{tabular}\par%
      \vskip 1.0cm
    \bfseries\fontsize{16bp}{31bp}\selectfont
      \cust@date@zh@shortbig
  \end{titlepage}%
  \cust@reset@main@language
}
% 研究生（博士，硕士）中文内页：
\newcommand\cust@title@page@graduate@in{
\custsetup{language=chinese}%
  \begin{titlepage}%
    \cust@pdfbookmark{封面}%
    \centering
    \parbox[t][0.6cm][t]{\textwidth}{%
      \raggedright\sffamily\fontsize{12bp}{22bp}\selectfont
      \textsf{中图分类号：}\cust@underline[2cm]{}
      \hspace{0.5\textwidth}
      \textsf{密级：}\cust@underline[2cm]{\cust@secret@level}\\
      \textsf{UDC：}\cust@underline[3.28cm]{}
      \hspace{0.5\textwidth}
      \textsf{编号：}\cust@underline[2cm]{}
      }
      \par
    \vskip 2.5cm%
    %论文题目，宽度为\textwidth
    \parbox[t][5.5cm][c]{\textwidth}{%
      \centering\sffamily\bfseries\fontsize{22bp}{35bp}\selectfont
      \cust@title\par}
    \vskip 0.1cm%
    %作者信息
    \ifcust@degree@type@professional
       \sffamily\fontsize{14bp}{31bp}\selectfont
         \begin{tabular}{l@{~~}c}
             \makebox[9em][s]{学位授予单位及代码}:&\underline{\makebox[13em][c]{长春理工大学（10186）}}\\
             \makebox[9em][s]{类别领域名称及代码}:&\underline{\makebox[13em][c]{\cust@speciality}}\\
             \makebox[4em][s]{研究方向}:&\underline{\makebox[13em][c]{\cust@speciality}}\\
             \makebox[6em][s]{申请学位级别}:&\underline{\makebox[13em][c]{\cust@thesis@level}}\\
             \makebox[5em][s]{研究生姓名}:&\underline{\makebox[13em][c]{\cust@author}}\\
             \makebox[6em][s]{指导教师姓名}:&\underline{\makebox[13em][c]{\cust@supervisor@names}}\\
             \makebox[6em][s]{企业行业导师}:&\underline{\makebox[13em][c]{\cust@advisor@names}}\\
             \makebox[6em][s]{论文起止时间}:&\underline{\makebox[13em][c]{\cust@start@date $\sim$ \cust@date@zh@short}}\\
         \end{tabular}
    \else
       \sffamily\fontsize{14bp}{31bp}\selectfont
         \begin{tabular}{l@{~~}c}
             \makebox[9em][s]{学位授予单位及代码}:&\underline{\makebox[13em][c]{长春理工大学（10186）}}\\
             \makebox[7em][s]{学科专业及代码}:&\underline{\makebox[13em][c]{\cust@speciality}}\\
             \makebox[4em][s]{研究方向}:&\underline{\makebox[13em][c]{\cust@speciality}}\\
             \makebox[6em][s]{申请学位级别}:&\underline{\makebox[13em][c]{\cust@thesis@level}}\\
             \makebox[5em][s]{研究生姓名}:&\underline{\makebox[13em][c]{\cust@author}}\\
             \makebox[6em][s]{指导教师姓名}:&\underline{\makebox[13em][c]{\cust@supervisor@names}}\\
             \makebox[6em][s]{论文起止时间}:&\underline{\makebox[13em][c]{\cust@start@date $\sim$ \cust@date@zh@short}}\\
         \end{tabular} 
    \fi
    \vskip 1.0cm
  \end{titlepage}%
  \cust@reset@main@language
}
% 研究生（博士，硕士）英文封面
\newcommand\cust@title@page@graduate@en{%
  \custsetup{language=english}%
  \begin{titlepage}%
    \cust@pdfbookmark{Title page}%
    \centering
    \parbox[t][0.4cm][t]{\textwidth}{%
      \raggedleft\fontsize{14bp}{14bp}\selectfont
      \null\cust@secret@level@en\par}\par
    \vskip 0.5cm%
    \parbox[t][4.5cm][c]{\textwidth}{%
      \centering\sffamily\bfseries\fontsize{22bp}{30bp}\selectfont
      \cust@title@en\par}
    \vskip 2.5cm
      by\par
    \vskip 1cm
      {\sffamily\bfseries\fontsize{14bp}{20bp}\selectfont
      \cust@author@en\par}
    \vskip 0.5cm
      Dissertation submitted to\par
    \vskip 0.5cm
    {\sffamily\bfseries\fontsize{14bp}{20bp}\selectfont
      Changchun University of Science and Technology\par}%
    \vskip 0.5cm
    in partial fulfillment of the requirements\\
for the degree of \par
    \vskip 0.5cm
    \ifcust@degree@type@academic
      \begingroup
        \sffamily\bfseries\fontsize{14bp}{20bp}\selectfont
        \ifcust@degree@doctor
          Doctor of Philosophy
        \else
          \cust@degree@area@en
        \fi
        \par
      \endgroup
    \else
      \begingroup
         \sffamily\bfseries\fontsize{14bp}{20bp}\selectfont
        \ifcust@degree@doctor
          Professional Doctor of Philosophy of \cust@speciality@en
        \else
          Professional Master of \cust@speciality@en
        \fi
        \par
      \endgroup
    \fi
    \vskip 1.6cm%
    {\fontsize{16bp}{30bp}\selectfont
      \begin{tabular}{@{}c@{}}%
        \cust@supervisor@en@line \\
%        \ifx\cust@advisor\@empty
%        \else
%          \cust@advisor@en@line \\
%        \fi
        \cust@date@en@short
      \end{tabular}\par}%
  \end{titlepage}%
  \cust@reset@main@language
}

\newbox\cust@title@box

% 本科生的封面
\newcommand\cust@title@page@bachelor{
\custsetup{language=chinese}%
  \begin{titlepage}%
    \cust@pdfbookmark{封面}%
    \centering
    \parbox[t][0.6cm][t]{\textwidth}{%
      \raggedright\sffamily\fontsize{12bp}{12bp}\selectfont
      \textsf{编号}\cust@underline[2cm]{}\par
      }\par
    \vskip 0.5cm%
    \includegraphics[height=3.1496cm]{figures/cust-name.pdf}\par
    \vskip 2.3866cm%bp:磅 此为图片和论文类型间距。
    {\sffamily\fontsize{26bp}{21bp}\selectfont
      \cust@thesis@name}%\sffamily为无衬线字体
    \ifcust@degree@type@academic
      \vskip 0.1533cm%此为论文类型与论文题目间距
    \else
      \vskip 0.1533cm%
    \fi
    \vskip 0.1cm%
    %论文题目，宽度为\textwidth
    \parbox[t][5.5cm][c]{\textwidth}{%
      \centering\sffamily\bfseries\fontsize{22bp}{35bp}\selectfont
      \cust@title\par
      \cust@title@en}
    \vskip 0.1cm%
    %作者信息
    {\sffamily\fontsize{16bp}{31bp}\selectfont
    \begin{tabular}{c@{~~}c}
        \makebox[4em][s]{学生姓名}:&\underline{\makebox[13em][c]{\cust@author}}\\
        \makebox[4em][s]{专业}:&\underline{\makebox[13em][c]{\cust@speciality}}\\
        \makebox[4em][s]{学号}:&\underline{\makebox[13em][c]{\cust@student@id}}\\
        \makebox[4em][s]{指导教师}:&\underline{\makebox[13em][c]{\cust@supervisor@names}}\\
        \makebox[4em][s]{学院}:&\underline{\makebox[13em][c]{\cust@department}}\\
    \end{tabular}
    \vskip 1.0cm
    \cust@date@zh@shortbig}
  \end{titlepage}%
  \cust@reset@main@language
}

% 重新定义 \cs{maketitle}，调用 \cs{cust@makezhtitle}, \cs{cust@makeentitle}
% 分别生成中、英文封面。
\renewcommand\maketitle{%
  \newgeometry{margin=2.5cm}%
  \pagenumbering{Alph}%
  \pagestyle{empty}%
  \ifcust@degree@graduate
    \cust@title@page@graduate@zh
    \cust@title@page@graduate@in
    \cust@title@page@graduate@en
  \else
    \cust@title@page@bachelor
  \fi
  \cleardoublepage
  \restoregeometry
  \pagestyle{plain}%
}


% \subsection{原创性声明}

% 定义原创性声明
\newcommand\cust@commitment{%
\linespread{1.5}\selectfont 
1.\quad 本人承诺：所呈交的毕业设计(论文)《\cust@title》，是认证学习理解学校的《长春理工大学本科生毕业设计(论文)工作条例》后，在教师的指导下，保质保量独立地完成了任务书中规定的内容，不弄虚作假，不抄袭别人的工作内容。

2.\quad 本人在毕业设计(论文)中引用他人的观点和成果，均在文中加以注释或以参开文献形式列出，对本文的研究工作做出重要贡献的个人和集体均已在文中注明。

3.\quad 在毕业(论文)中对侵犯任何方面知识产权的行为，由本人承担相应的法律责任。

4.\quad 本人完全了解学校关于保存、使用毕业设计(论文)的规定，即：按照学校要求提交论文和相关材料的印刷本和电子版本；同意学校保留毕业设计(论文)的复印件和电子版本，允许被查阅和借阅；学校可以采用影印、缩印或其他复制手段保存毕业设计(论文)，可以公布其中的全部或部分内容。
%  \end{enumerate}

\quad 以上承诺的法律结果将完全由本人承担！
 }
\newcommand\cust@originality{%
  \linespread{1.5}\selectfont
  本人郑重声明：所呈交的{\cust@thesis@level}学位论文《\cust@title》是本人在指导导师的指导下，独立进行研究工作所取得的成果。%
  除文中已经注明引用的内容外，本论文不包含任何他个人或集体已经发表或撰写过的作品成果。对本文的研究做出重要贡献的个人和集体，均已在文中以明确方式标明。本人完全意识到本声明的法律结果由本人承担。}
\newcommand\cust@authorization{%
  \linespread{1.5}\selectfont
  本学位论文作者及指导教师完全了解长春理工大学{\cust@thesis@level}学位论文版权使用规定，即：
  研究生在校攻读学位期间论文工作的知识产权单位属长春理工大学。本人保证毕业离校后，发表论文或使用论文工作成果时署名单位仍然为长春理工大学。同意长春理工大学保存并使用学位论文；同意长春理工大学向国家图书馆、中国学术期刊（光盘版）电子杂志社、中国科学信息研究所送交学位论文的复印件和电子版，允许论文被查阅和借阅。（涉密论文在解密后遵守此规定）\par
  论文涉密情况约定：(打"$\checkmark$"选择)}
  %
  % 生成空的下划线
\newcommand\cust@underline[2][3.2cm]{\underline{\hb@xt@ #1{\hss#2\hss}}}

\newcommand\cust@checkbox{%
  \makebox[\z@][l]{$\square$}%
  \raisebox{-0.2ex}{\hspace{0.1em}$\checkmark$}%
}

\newcommand\copyrightpage{%
\ifcust@degree@bachelor
  \begin{titlepage}%
    \cust@pdfbookmark{原创性和授权使用声明}%
    \null
    %\vskip 0.01cm
    {\centering\sffamily\fontsize{16bp}{32bp}\selectfont
      毕业设计(论文)原创承诺书\par}%
    \vskip 1.2cm
    \cust@commitment\par
    \vskip 1.5cm%
    作者签名：\hspace{3.7cm}%
    \hspace{2cm}年\hspace{1cm}月\hspace{1cm}日%
    \vskip 0.5cm%
   \end{titlepage}%
\else
  \begin{titlepage}%
    \cust@pdfbookmark{原创性和授权使用声明}%
    \null
    %\vskip 0.01cm
    {\centering\sffamily\fontsize{16bp}{32bp}\selectfont
      长春理工大学学位论文原创性声明\par}%
    %\vskip 0.2cm
    \cust@originality\par
    \vskip 0.2cm%
    作者签名：\cust@underline{}\hspace{2.7cm}%
    \cust@underline[2cm]{}年\cust@underline[1cm]{}月\cust@underline[1cm]{}日%
    \vskip 0.5cm%
    {\centering\sffamily\fontsize{16bp}{32bp}\selectfont
      长春理工大学学位论文版权使用授权书\par}%
    %\vskip 0.2cm
    \cust@authorization\par
    \vskip 0.2cm%
    \ifx\cust@secret@level\@empty
      \cust@checkbox{} 本论文非涉密论文\par
      $\square$ 本论文属于涉密论文，在\cust@underline[1.5cm]{}年解密后使用本授权书。\par
    \else
      $\square$ 本论文非涉密论文\par
      \cust@checkbox{} 本论文属于涉密论文，在\cust@underline[1.5cm]{\cust@secret@year}年解密后使用本授权书。\par
    \fi
    \vskip 0.2cm%
    作者签名：\cust@underline{}\hspace{2.7cm}%
    \cust@underline[2cm]{}年\cust@underline[1cm]{}月\cust@underline[1cm]{}日%
    \vskip 0.3cm%
    导师签名：\cust@underline{}\hspace{2.7cm}%
    \cust@underline[2cm]{}年\cust@underline[1cm]{}月\cust@underline[1cm]{}日\hspace{2.7cm}%
  \end{titlepage}%
\fi
}
%\ifcust@degree@bachelor
%  \let\copyrightpage\relax
%\fi
% Reserved for compatibility until 2020-07-01.
\let\makestatement\copyrightpage


% \subsection{章节标题}

% 标题最多允许使用五级。
\setcounter{secnumdepth}{5}

% 研究生规定章题为两字时中间空两字，三字时空一字，四字时空半字，四字以上不空。
% 这里用 \LaTeX3 的 \cs{str\_count:N} 判断字数。
% 注意，\pkg{stringstrings} 宏包会导致范数命令 \verb+\|+ 被修改。
\newcount\cust@titlelength
\DeclareRobustCommand\cust@spacetitle[1]{%
  \cust@titlelength=\csname str_count:N\endcsname{#1}%
  \begingroup
    \ifcust@degree@graduate
      \ifcase\cust@titlelength
      \or\or
        \ziju{2}%
      \or
        \ziju{1}%
      \or
        \ziju{0.5}%
      \fi
    \else
      \if@mainmatter\else
        \ifcase\cust@titlelength
        \or\or
          \ziju{1}%
        \or\or
          \ziju{0.5}%
        \fi
      \fi
    \fi
    #1%
  \endgroup
}

% 五级节标题和脚注需要使用带圈的数字，这里使用 \cs{cust@circlefont} ：
\newcommand\cust@textcircled[1]{%
  \ifnum\value{#1}<21\relax
    {\symbol{\numexpr\value{#1} + "245F\relax}}%
  \else
    \cust@error{Cannot display more than 20 footnotes}%
  \fi
}

% 用 \pkg{ctex} 的接口设置全部章节标题格式。

% 各章标题（章标题）：宋体三号字即即 16 磅加粗居中，单倍行距，段前 24 磅，段后 18 磅，
% 章序号与章名间空一字。

% 由于 Word 模板中使用“单倍行距”，还“对齐到网格”，这在 TeX 中不容易实现。
% 所以目前按照默认的行距。

% 注意 \pkg{ctex} v2.4.3 以下版本的bug会导致章节标题前后的距离的实际值偏大。
% 另外 \pkg{ctex} v2.2 前的beforeskip的符号有特殊意义。
\ctexset{
  chapter = {
    format      = \centering\rmfamily\bfseries\fontsize{16bp}{26.67bp}\selectfont,
    nameformat  = {},
    titleformat = \cust@spacetitle,
    number      = \thechapter,
    aftername   = \hspace{\ccwd},
    beforeskip  = 24bp,
    afterskip   = 18bp,
    fixskip     = true,
  },
}

% 各章1级节标题：宋体四号即14磅，加粗，左顶格但缩进两个字符，单倍行距，段前 24 磅，段后 6 磅，
% 序号与题名间空一字。
\ctexset{
  section = {
    format     = \rmfamily\bfseries\fontsize{14bp}{23.33bp}\selectfont,
    aftername  = \hspace{\ccwd},
    indent     = 2\ccwd,
    beforeskip = 24bp,
    afterskip  = 6bp,
  },
  %
% 各章2级节标题：宋体小四号即 12磅，加粗，左缩进两字，单倍行距，段前 12 磅，段后 6 磅，
  % 序号与题名间空一字。
  subsection = {
    format     = \rmfamily\bfseries\fontsize{12bp}{21.67bp}\selectfont,
    aftername  = \hspace{\ccwd},
    indent     = 2\ccwd,
    beforeskip = 12bp,
    afterskip  = 6bp,
  },
% 各章3级节标题：宋体小四号即 12磅，加粗，左缩进两字，单倍行距，段前 12 磅，段后 6 磅，
  % 序号与题名间空一字。
  subsubsection = {
    format     = \rmfamily\bfseries\fontsize{12bp}{20bp}\selectfont,
%    number     = \arabic{subsubsection},
    aftername  = .\hspace{0.5\ccwd},
    indent     = 2\ccwd,
    beforeskip = \z@,
    afterskip  = \z@,
  },
  %
%4级节标题的格式使用宋体小四号即12磅加粗，左缩进两字，行距 20 磅，段前段后 0 磅，序号与题名间空半字宽。
  paragraph = {
    format     = \rmfamily\fontsize{12bp}{20bp}\selectfont,
    number     = \arabic{paragraph}）, 
    aftername  = \hspace{0.5\ccwd},
    indent     = 2\ccwd,
    beforeskip = \z@,
    afterskip  = \z@,
    runin      = false,
  },
% 按照 Word 模板的格式，五级节标题：宋体 12 磅，左缩进两字，行距 20 磅，
  % 段前段后 0 磅，序号使用全宽括号，与题名间空半字宽。
  subparagraph = {
    format     = \rmfamily\fontsize{12bp}{20bp}\selectfont,
    number     = (\arabic{paragraph}),
    aftername  = \hspace{0.5\ccwd},
    indent     = 2\ccwd,
    beforeskip = \z@,
    afterskip  = \z@,
    runin      = false,
  },
% 按照 Word 模板的格式，6级节标题：宋体 12 磅，左缩进两字，行距 20 磅，
  % 段前段后 0 磅，序号使用数字带圈，与题名间空半字宽。
% 六级标题通常不设置，因此注释掉
%  subparagraph = {
%    format     = \rmfamily\fontsize{12bp}{20bp}\selectfont,
%    number     = \cust@textcircled{subparagraph},
%    aftername  = \hspace{0.5\ccwd},
%    indent     = 2\ccwd,
%    beforeskip = \z@,
%    afterskip  = \z@,
%    runin      = false,
%  },
}

\ifcust@degree@bachelor
  \ifcust@main@language@english
    \custsetup{section-style = arabic}
  \fi
\fi
\cust@option@hook{main-language}{%
  \ifcust@degree@bachelor
    \ifcust@main@language@english
      \custsetup{section-style = arabic}%
    \fi
  \fi
}
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% 本科生章节格式标题
% 在研究生格式的基础上再设置本科生的章节标题格式。
\ifcust@degree@bachelor
  \setcounter{secnumdepth}{5}
  \ctexset{
  %
  % 论文的致谢、目录、摘要和参考文献等标题用三号（16 bp）宋体字，居中，加粗
  % 这通过 \cs{if@mainmatter} 区分。
  % 正文中的标题分章、节、段三级；章标题居中，节、段标题居左缩进两字符，分别用三号（16 bp）宋体、四号（14 bp）宋体和小四号宋体（12bp）均加粗。
    chapter = {
      format = {
        \centering\rmfamily\bfseries
        \if@mainmatter
          \fontsize{16bp}{26.67bp}\selectfont
        \else
          \fontsize{16bp}{33bp}\selectfont
        \fi
      },
    },
    section = {
      format = \rmfamily\bfseries\fontsize{14bp}{22.33bp}\selectfont,
      indent     = 2\ccwd,%缩进2字符
      beforeskip = 24bp,%段前24磅
      afterskip  = 6bp,%段前6磅
    },
    subsection = {
      format    = \rmfamily\bfseries\fontsize{12bp}{22.33bp}\selectfont,
      indent     = 2\ccwd,
      beforeskip = 24bp,
      afterskip  = 6bp,
    },
    subsubsection = {
      format    = \rmfamily\bfseries\fontsize{12bp}{22bp}\selectfont,
      indent    = 2\ccwd,
    },
    paragraph = {
      format    = \rmfamily\bfseries\fontsize{12bp}{22bp}\selectfont,
      aftername = {},
      indent    = 2\ccwd,
    },
  }
  %
% 如果标题的编号为中文编号，需要按照如下修改。
% \ifcust@section@style@arabic\else
%   \ctexset{
%     chapter = {
%       number = \chinese{chapter},
%     },
%     section = {
%       name   = {第,节},
%       number = \chinese{section},
%     },
%     subsection = {
%       number    = \chinese{subsection},
%       aftername = {、},
%     },
%   }
% \fi
\fi

% 默认的 \cs{chapter*} 生成的章标题没有编号、不更改页眉，
% 也不添加进目录或 PDF 书签。
% 然而像摘要、目录、符号说明这样的章节，它们不需要编号、不加入目录，
% 但是需要修改页眉，并且加入 PDF 标签。
% 所以我们新定义 \cs{cust@chapter} 用于处理这些章节。%
\NewDocumentCommand\cust@chapter{o m}{%
  \if@openright\cleardoublepage\else\clearpage\fi
  \IfValueTF{#1}{%
    \cust@pdfbookmark{#1}%
    \chaptermark{#1}%
  }{%
    \cust@pdfbookmark{#2}%
    \chaptermark{#2}%
  }%
  \chapter*{#2}}


% \subsection{摘要}

% 中文摘要环境。
\newcommand\cust@keywords@text{%
  \cust@clist@use{\cust@keywords}{；}%
}
\newcommand\cust@keywords@en@text{%
  \cust@clist@use{\cust@keywords@en}{; }%
}
\newenvironment{abstract}{%
  \custsetup{language=chinese}%
  \cust@chapter{摘要}%
}{
  \par\null\par\noindent\hangindent=4\ccwd\relax
  \textbf{关键词}：\cust@keywords@text\par
  \cust@reset@main@language
}

% 英文摘要环境
\newenvironment{abstract*}{%
  \custsetup{language=english}%
  \ifcust@degree@graduate
    \cust@chapter[Abstract]{ABSTRACT}%
    \pagenumbering{Roman}%《规范》要求重新编页码
  \else
    \begingroup
      % 本科生的英文摘要使用小二号衬线体
      \ctexset{chapter/format=\centering\fontsize{18bp}{33bp}\selectfont}%
      \cust@chapter{ABSTRACT}%
      \pagenumbering{Roman}%《规范》要求重新编页码
    \endgroup
  \fi
}{
  \par\null\par\noindent\hangindent=5.3em\relax
  \textbf{Key Words}: \cust@keywords@en@text\par
  \ifcust@degree@graduate
    \cleardoublepage
  \fi
  \cust@reset@main@language
}

% Reserved for compatibility until 2020-07-01.
\newenvironment{enabstract}{%
  \begin{abstract*}%
}{%
  \end{abstract*}%
}


% \subsection{目录}

% 《规范》要求目录独立采用罗马数字编页码，所以必须另页起。包括正文章节（一般到三级标题）、参考文献、附录、致谢及各部分序号、名称、页码。
\renewcommand\tableofcontents{%
  \clearpage% 
  \pagenumbering{Roman}%
  \pagestyle{plain}%
  \cust@chapter{\contentsname}%
  \@starttoc{toc}%
}

% 下面用 \pkg{titletoc} 宏包设置目录内容的格式。
% 先定义目录线：
\newcommand\cust@leaders{\titlerule*[9bp]{\textperiodcentered}}

% 各章目录要求宋体 14 磅，单倍行距，段前 6 磅，段后 0 磅，两端对齐，
% 页码右对齐，章序号与章名间空一字。
% 但是 Word 模板中实际是行距 20 磅。
\ifcust@degree@graduate
  \titlecontents{chapter}
    [\z@]{\addvspace{6bp}\fontsize{14bp}{20bp}\selectfont}
    {\contentspush{\thecontentslabel\hspace{\ccwd}}}{}
    {\fontsize{12bp}{20bp}\selectfont\cust@leaders\contentspage}
    %
    % 一级节标题目录要求宋体 12 磅，单倍行距，左缩进一字，段前 6 磅，段后 0 磅，
    % 两端对齐，页码右对齐，序号与题名间空一字。
    % Word 模板中实际是行距 20 磅，段前 0 磅。
  \titlecontents{section}
    [\ccwd]{\fontsize{12bp}{20bp}\selectfont}
    {\contentspush{\thecontentslabel\hspace{\ccwd}}}{}
    {\cust@leaders\contentspage}
    %
    % 二级节标题目录要求仿宋 12 磅，单倍行距，左缩进两字，段前 6 磅，段后 0 磅，
    % 两端对齐，页码右对齐，序号与题名间空一字。
    % Word 模板中实际是行距 20 磅，段前 0 磅。
  \titlecontents{subsection}
    [2\ccwd]{\fangsong\fontsize{12bp}{20bp}\selectfont}
    {\contentspush{\thecontentslabel\hspace{\ccwd}}}{}
    {\cust@leaders\contentspage}
    %
    % 本科生的目录使用小四宋体（同正文字体），其他同研究生的格式相近。
\else
  \titlecontents{chapter}
    [\z@]{\normalsize}
    {\contentspush{\thecontentslabel\unskip\hspace{\ccwd}}}{}
    {\cust@leaders\contentspage}
  \titlecontents{section}
    [\ccwd]{\normalsize}
    {\contentspush{\thecontentslabel\hspace{\ccwd}}}{}
    {\cust@leaders\contentspage}
  \titlecontents{subsection}
    [2\ccwd]{\normalsize}
    {\contentspush{\thecontentslabel
      \ifcust@section@style@arabic\hspace{\ccwd}\else 、\fi}}{}
    {\cust@leaders\contentspage}
\fi

% 本科生要求目录中正文每章前多空一行，而目录、附录等章则不需要空行，
% 所以不能简单判断 \cs{if@mainmatter}，需要重新定义 \cs{mainmatter} 等命令。
\newif\ifcust@addtocspace
\ifcust@degree@bachelor
  \cust@addtocspacetrue
  \g@addto@macro\frontmatter{\cust@addtocspacefalse}%
  \g@addto@macro\mainmatter{\cust@addtocspacetrue}%
  \g@addto@macro\backmatter{\cust@addtocspacefalse}%
  \g@addto@macro\appendix{\cust@addtocspacefalse}%
\fi

% 处理本科生在目录中添加空行。
\renewcommand\chapter{%
  \if@openright\cleardoublepage\else\clearpage\fi
  \thispagestyle{\CTEX@chapter@pagestyle}%
  \global\@topnum\z@
  \@afterindenttrue
  \ifcust@degree@bachelor
    \ifcust@addtocspace
      \addtocontents{toc}{\protect\addvspace{12bp}}%
    \fi
  \fi
  \secdef\@chapter\@schapter
}

% 研究生要求图、表的清单须另页起。
\newlength{\cust@lof@label@width}
\newcommand\cust@set@lof@format{%
  \settowidth{\cust@lof@label@width}{\figurename~9.99}%
  \addtolength{\cust@lof@label@width}{1em}%
  \titlecontents{figure}%
    [\cust@lof@label@width]{\normalsize}%
    {\contentslabel[\figurename~\thecontentslabel]{\cust@lof@label@width}}{}%
    {\cust@leaders\contentspage}%
  \titlecontents{table}%
    [\cust@lof@label@width]{\normalsize}%
    {\contentslabel[\tablename~\thecontentslabel]{\cust@lof@label@width}}{}%
    {\cust@leaders\contentspage}%
}
\cust@set@lof@format
\cust@option@hook{main-language}{\cust@set@lof@format}
\renewcommand\listoffigures{%
%  \ifcust@degree@graduate
    \cleardoublepage
    \pagenumbering{Roman}
%  \fi
  \cust@chapter{\listfigurename}%
  \@starttoc{lof}%
}
\renewcommand\listoftables{%
%  \ifcust@degree@graduate
    \cleardoublepage
    \pagenumbering{Roman}
%  \fi
  \cust@chapter{\listtablename}%
  \@starttoc{lot}%
}


% \subsection{符号说明}

% 《规范》中要求符号说明另页起，标题字体字号等同论文正文。
\newenvironment{notation}{%
%  \ifcust@degree@graduate
    \cleardoublepage
    \pagenumbering{Roman}
%%    \pagestyle{headings}%没有页脚
    \pagestyle{plain}
%  \fi
  \cust@chapter{\cust@notation@name}%
}{%
%  \ifcust@degree@graduate
    \clearpage
    \pagenumbering{Roman}
    \pagestyle{plain}%
%  \fi
}%
\newcommand*\notationlabel[1]{#1\hfil}%
\newenvironment{notationlist}[1]{%
  \list{}{%
    \itemsep 3bp%
    \labelwidth #1\relax%
    \labelsep 1em%
    \leftmargin\labelwidth
    \advance\leftmargin\labelsep
    \advance\leftmargin 3em%
    \rightmargin 3em%
    \let\makelabel\notationlabel
  }%
}{%
  \endlist
}


% \subsection{正文}

% \cs{sloppy} 可以减少“overfull boxes”。
\sloppy

% 禁止扩大段间距。（\href{https://github.com/custtug/custhesis/issues/209}{
%   custtug/custhesis\#209}）
\raggedbottom

% 段间距 0 磅。
\setlength{\parskip}{\z@}

% 首段缩进。
\ctexset{autoindent=2}

% 首段缩进。
\let\@afterindentfalse\@afterindenttrue
\@afterindenttrue

% URL 的字体设为保持原样。
\urlstyle{same}

% 使用 \pkg{xurl} 宏包的方法，增加 URL 可断行的位置。
\def\UrlBreaks{%
  \do\/%
  \do\a\do\b\do\c\do\d\do\e\do\f\do\g\do\h\do\i\do\j\do\k\do\l%
     \do\m\do\n\do\o\do\p\do\q\do\r\do\s\do\t\do\u\do\v\do\w\do\x\do\y\do\z%
  \do\A\do\B\do\C\do\D\do\E\do\F\do\G\do\H\do\I\do\J\do\K\do\L%
     \do\M\do\N\do\O\do\P\do\Q\do\R\do\S\do\T\do\U\do\V\do\W\do\X\do\Y\do\Z%
  \do0\do1\do2\do3\do4\do5\do6\do7\do8\do9\do=\do/\do.\do:%
  \do\*\do\-\do\~\do\'\do\"\do\-}
\Urlmuskip=0mu plus 0.1mu

% 脚注用带圈的数字：
\renewcommand\thefootnote{\cust@textcircled{footnote}}

% LaTeX 默认脚注按章计数，即每章的开始才重置脚注计数器；我们修改为按页计数。
% 简单的|\@addtoreset{footnote}{page}|并不可靠，
% \footnote{\url{https://texfaq.org/FAQ-footnpp.html}}
% 所以我们使用 \pkg{footmisc} 宏包。

% 脚注线长为版心宽度的四分之一：
\renewcommand\footnoterule{%
  \kern-3\p@
  \hrule\@width.25\textwidth
  \kern2.6\p@}
  %
  % 注文缩进两字：
\renewcommand\@makefntext[1]{%
  \parindent 2\ccwd\relax
  \noindent
  \hb@xt@2\ccwd{\hss\@makefnmark}#1}


% \subsection{列表}
% \label{sec:list}

% 调整列表中各项之间过大的间距。
\setlength\partopsep{\z@}
\newcommand\cust@nolistsep{%
  \parsep 0\p@ \@plus.2\p@
  \topsep 0\p@ \@plus.2\p@
  \itemsep0\p@ \@plus.2\p@
}
\def\@listi{\leftmargin\leftmargini
            \cust@nolistsep}
\let\@listI\@listi
\@listi
\def\@listii {\leftmargin\leftmarginii
              \labelwidth\leftmarginii
              \advance\labelwidth-\labelsep
              \cust@nolistsep}
\def\@listiii{\leftmargin\leftmarginiii
              \labelwidth\leftmarginiii
              \advance\labelwidth-\labelsep
              \cust@nolistsep}


% \subsection{图、表、算法}

% \LaTeX{} 对放置诸如图、表、算法等浮动体的要求比较强，这里按照 UK TeX FAQ 的建议
% \footnote{\url{https://texfaq.org/FAQ-floats}} 对其适当放宽。
\renewcommand\topfraction{.85}
\renewcommand\bottomfraction{.7}
\renewcommand\textfraction{.15}
\renewcommand\floatpagefraction{.66}
\renewcommand\dbltopfraction{.66}
\renewcommand\dblfloatpagefraction{.66}
\setcounter{topnumber}{9}
\setcounter{bottomnumber}{9}
\setcounter{totalnumber}{20}
\setcounter{dbltopnumber}{9}

% 修改默认的浮动体描述符为 |h|。也可以修改为t,b,p
\def\fps@figure{h}
\def\fps@table{h}

% 用 \pkg{caption} 宏包设置图、表的格式：

% 图号、图题置于图的下方，宋体五号字 10.5 磅居中，单倍行距，段前 6 磅，段后 12 磅，
% 图号与图题文字之间空一字。
% 图注位于图的下方，左缩进两字，续行悬挂缩进左对齐，两端对齐。

% 表号、表题置于表的上方，宋体五号字，即 10.5 磅居中，单倍行距，段前 6 磅，段后 6 磅，
% 表号与表题文字之间空一字。
% 表注左缩进两字，续行悬挂缩进左对齐，两端对齐。
\setlength{\floatsep}{6bp}
\setlength{\textfloatsep}{6bp}
\setlength{\intextsep}{6bp}

\DeclareCaptionFont{cust}{%
  \ifcust@language@chinese
    \fontsize{10.5bp}{13.65bp}\selectfont
  \else
    \fontsize{10.5bp}{12.075bp}\selectfont
  \fi
}

\captionsetup{
  font           = cust,
  labelsep       = quad,
  skip           = 6bp,
  figureposition = bottom,
  tableposition  = top,
}
\ifcust@degree@graduate
  \captionsetup{font+=bf}
  \captionsetup[table]{font+=sf}
\fi
\captionsetup[figure]{
  belowskip = 6bp,
}

% 由于 LaTeX2e kernel 的问题，图表等浮动体与文字前后的距离不一致，需要进行 patch。
% 参考 \href{https://github.com/tuna/thuthesis/issues/614}{tuna/thuthesis/issues\#614}、
% \url{https://www.zhihu.com/question/46618031} 和
% \url{https://tex.stackexchange.com/a/40363/82731}。
%    \begin{macrocode}
\patchcmd{\@addtocurcol}%
  {\vskip \intextsep}%
  {\edef\save@first@penalty{\the\lastpenalty}\unpenalty
   \ifnum \lastpenalty = \@M  % hopefully the OR penalty
     \unpenalty
   \else
     \penalty \save@first@penalty \relax % put it back
   \fi
   \ifnum\outputpenalty <-\@Mii
     \addvspace\intextsep
     \vskip\parskip
   \else
     \addvspace\intextsep
   \fi}%
  {}{\cust@patch@error{\@addtocurcol}}
\patchcmd{\@addtocurcol}%
  {\vskip\intextsep \ifnum\outputpenalty <-\@Mii \vskip -\parskip\fi}%
  {\ifnum\outputpenalty <-\@Mii
     \aftergroup\vskip\aftergroup\intextsep
     \aftergroup\nointerlineskip
   \else
     \vskip\intextsep
   \fi}%
  {}{\cust@patch@error{\@addtocurcol}}
\patchcmd{\@getpen}{\@M}{\@Mi}
  {}{\cust@patch@error{\@getpen}}

% 新定义了 \cs{note} 来生成图表的附注。
% 如果用 \cs{caption} 生成图表的附注会导致图表的序号有误；
% 如果用 \cs{bicaption} 会导致表注无法置于表后，而且对齐方式不对。
\newcommand\note[1]{%
  \begingroup
    \captionsetup{
      font          = cust,
      margin        = 2\ccwd,
      position      = bottom,
    }%
    \caption*{#1}%
  \endgroup
}

% 表格默认字号略小
\patchcmd\@floatboxreset{%
  \normalsize
}{%
  \small
}{}{\cust@patch@error{\@floatboxreset}}

% 对 \pkg{longtable} 跨页表格进行相同的设置。
%
% 在 Word 模板中按照正确的设置（需要去掉文档网格），
% 中文模板每页能装下 1 行标题、1 行表头、30 行表身，
% 英文模板每页能装下 1 行标题、1 行表头、33 行表身。
%    \begin{macrocode}
\AtEndOfPackageFile*{longtable}{
  \AtBeginEnvironment{longtable}{%
    \ifdim\f@size pt > 12pt\relax
      \small
    \fi
  }
}


% \subsection{参考文献}

\PassOptionsToPackage{compress}{natbib}

\AtEndOfPackageFile*{natbib}{
  % 定义几种引用文献的标注样式。
  \newcommand\bibstyle@super{\bibpunct{[}{]}{,}{s}{,}{\textsuperscript{,}}}
  \newcommand\bibstyle@inline{\bibpunct{[}{]}{,}{n}{,}{,}}
  \newcommand\bibstyle@authoryear{\bibpunct{(}{)}{;}{a}{,}{,}}
  \@namedef{bibstyle@author-year}{\bibstyle@authoryear}
  %
  % 几种种引用样式，与 \file{bst} 文件名保持一致，
  % 这样在使用 \cs{bibliographystyle} 选择参考文献表的样式时也会设置对应的引用样式。
  \@namedef{bibstyle@custhesis-numerical}{\bibstyle@super}
  \@namedef{bibstyle@custhesis-authoryear}{\bibstyle@authoryear}
  \@namedef{bibstyle@custhesis-bachelor}{\bibstyle@super}
  %
  % 如果载入 `natbib` 前设置了 `cite-style`，这里先进行配置。
  \ifx\cust@cite@style\@empty\else
    \citestyle{\cust@cite@style}%
  \fi
  %
  % 定义接口 cite-style 切换引用样式。
  \cust@option@hook{cite-style}{%
    \citestyle{\cust@cite@style}%
  }
  %
  % 如果文献序号作为叙述文字的一部分，需要临时将文献序号与正文平排
  \DeclareRobustCommand\inlinecite{\@inlinecite}
  \def\@inlinecite#1{\begingroup\let\@cite\NAT@citenum\citep{#1}\endgroup}
  %
  % 修改引用的样式。
  % 这里在 filehook 中无法使用 \cs{patchcmd}，所以只能手动重定义。
  %
  % 将 super 式 \cs{citep} 引用的页码置于括号外。
  \renewcommand\NAT@citesuper[3]{%
    \ifNAT@swa
      \if*#2*\else
        #2\NAT@spacechar
      \fi
      % \unskip\kern\p@\textsuperscript{\NAT@@open#1\NAT@@close}%
      %  \if*#3*\else\NAT@spacechar#3\fi\else #1\fi\endgroup}
      \unskip\kern\p@
      \textsuperscript{%
        \NAT@@open#1\NAT@@close
        \if*#3*\else#3\fi
      }%
      \kern\p@
    \else
      #1%
    \fi
    \endgroup
  }
  %
  % 将 numbers 式 \cs{citep} 引用的页码置于括号外并改为上标。
  \renewcommand\NAT@citenum[3]{%
    \ifNAT@swa
      \NAT@@open
      \if*#2*\else
        #2\NAT@spacechar
      \fi
      % #1\if*#3*\else\NAT@cmt#3\fi\NAT@@close
      #1\NAT@@close
      \if*#3*\else
        \textsuperscript{#3}%
      \fi
    \else
      #1%
    \fi
    \endgroup
  }
  %
  % 在 filehook 中无法使用 \cs{patchcmd}，所以只能手动重定义。
  \def\NAT@citexnum[#1][#2]#3{%
    \NAT@reset@parser
    \NAT@sort@cites{#3}%
    \NAT@reset@citea
    \@cite{\def\NAT@num{-1}\let\NAT@last@yr\relax\let\NAT@nm\@empty
      \@for\@citeb:=\NAT@cite@list\do
      {\@safe@activestrue
      \edef\@citeb{\expandafter\@firstofone\@citeb\@empty}%
      \@safe@activesfalse
      \@ifundefined{b@\@citeb\@extra@b@citeb}{%
        {\reset@font\bfseries?}
          \NAT@citeundefined\PackageWarning{natbib}%
        {Citation `\@citeb' on page \thepage \space undefined}}%
      {\let\NAT@last@num\NAT@num\let\NAT@last@nm\NAT@nm
        \NAT@parse{\@citeb}%
        \ifNAT@longnames\@ifundefined{bv@\@citeb\@extra@b@citeb}{%
          \let\NAT@name=\NAT@all@names
          \global\@namedef{bv@\@citeb\@extra@b@citeb}{}}{}%
        \fi
        \ifNAT@full\let\NAT@nm\NAT@all@names\else
          \let\NAT@nm\NAT@name\fi
        \ifNAT@swa
        \@ifnum{\NAT@ctype>\@ne}{%
          \@citea
          \NAT@hyper@{\@ifnum{\NAT@ctype=\tw@}{\NAT@test{\NAT@ctype}}{\NAT@alias}}%
        }{%
          \@ifnum{\NAT@cmprs>\z@}{%
          \NAT@ifcat@num\NAT@num
            {\let\NAT@nm=\NAT@num}%
            {\def\NAT@nm{-2}}%
          \NAT@ifcat@num\NAT@last@num
            {\@tempcnta=\NAT@last@num\relax}%
            {\@tempcnta\m@ne}%
          \@ifnum{\NAT@nm=\@tempcnta}{%
            \@ifnum{\NAT@merge>\@ne}{}{\NAT@last@yr@mbox}%
          }{%
            \advance\@tempcnta by\@ne
            \@ifnum{\NAT@nm=\@tempcnta}{%
              % 在顺序编码制下，\pkg{natbib} 只有在三个以上连续文献引用才会使用连接号，
              % 这里修改为允许两个引用使用连接号。
              % 参考 https://tex.stackexchange.com/a/86991/82731 。
              %
              % \ifx\NAT@last@yr\relax
              %   \def@NAT@last@yr{\@citea}%
              % \else
              %   \def@NAT@last@yr{--\NAT@penalty}%
              % \fi
              \def@NAT@last@yr{-\NAT@penalty}%
            }{%
              \NAT@last@yr@mbox
            }%
          }%
          }{%
          \@tempswatrue
          \@ifnum{\NAT@merge>\@ne}{\@ifnum{\NAT@last@num=\NAT@num\relax}{\@tempswafalse}{}}{}%
          \if@tempswa\NAT@citea@mbox\fi
          }%
        }%
        \NAT@def@citea
        \else
          \ifcase\NAT@ctype
            \ifx\NAT@last@nm\NAT@nm \NAT@yrsep\NAT@penalty\NAT@space\else
              \@citea \NAT@test{\@ne}\NAT@spacechar\NAT@mbox{\NAT@super@kern\NAT@@open}%
            \fi
            \if*#1*\else#1\NAT@spacechar\fi
            \NAT@mbox{\NAT@hyper@{{\citenumfont{\NAT@num}}}}%
            \NAT@def@citea@box
          \or
            \NAT@hyper@citea@space{\NAT@test{\NAT@ctype}}%
          \or
            \NAT@hyper@citea@space{\NAT@test{\NAT@ctype}}%
          \or
            \NAT@hyper@citea@space\NAT@alias
          \fi
        \fi
      }%
      }%
        \@ifnum{\NAT@cmprs>\z@}{\NAT@last@yr}{}%
        \ifNAT@swa\else
          % 将 numerical 式 \cs{citet} 引用的页码置于括号外并改为上标。
          %
          % \@ifnum{\NAT@ctype=\z@}{%
          %   \if*#2*\else\NAT@cmt#2\fi
          % }{}%
          \NAT@mbox{\NAT@@close}%
          \@ifnum{\NAT@ctype=\z@}{%
            \if*#2*\else
              \textsuperscript{#2}%
            \fi
          }{}%
          \NAT@super@kern
        \fi
    }{#1}{#2}%
  }%
  %
  % 将 author-year 式 \cs{citep} 引用的页码置于括号外并改为上标：
  \renewcommand\NAT@cite%
      [3]{\ifNAT@swa\NAT@@open\if*#2*\else#2\NAT@spacechar\fi
          % #1\if*#3*\else\NAT@cmt#3\fi\NAT@@close\else#1\fi\endgroup}
          #1\NAT@@close\if*#3*\else\textsuperscript{#3}\fi\else#1\fi\endgroup}
  %
  % 调整 author-year 式 \cs{citet} 引用的页码。
  \def\NAT@citex%
    [#1][#2]#3{%
    \NAT@reset@parser
    \NAT@sort@cites{#3}%
    \NAT@reset@citea
    \@cite{\let\NAT@nm\@empty\let\NAT@year\@empty
      \@for\@citeb:=\NAT@cite@list\do
      {\@safe@activestrue
      \edef\@citeb{\expandafter\@firstofone\@citeb\@empty}%
      \@safe@activesfalse
      \@ifundefined{b@\@citeb\@extra@b@citeb}{\@citea%
        {\reset@font\bfseries ?}\NAT@citeundefined
                  \PackageWarning{natbib}%
        {Citation `\@citeb' on page \thepage \space undefined}\def\NAT@date{}}%
      {\let\NAT@last@nm=\NAT@nm\let\NAT@last@yr=\NAT@year
        \NAT@parse{\@citeb}%
        \ifNAT@longnames\@ifundefined{bv@\@citeb\@extra@b@citeb}{%
          \let\NAT@name=\NAT@all@names
          \global\@namedef{bv@\@citeb\@extra@b@citeb}{}}{}%
        \fi
      \ifNAT@full\let\NAT@nm\NAT@all@names\else
        \let\NAT@nm\NAT@name\fi
      \ifNAT@swa\ifcase\NAT@ctype
        \if\relax\NAT@date\relax
          \@citea\NAT@hyper@{\NAT@nmfmt{\NAT@nm}\NAT@date}%
        \else
          \ifx\NAT@last@nm\NAT@nm\NAT@yrsep
              \ifx\NAT@last@yr\NAT@year
                \def\NAT@temp{{?}}%
                \ifx\NAT@temp\NAT@exlab\PackageWarningNoLine{natbib}%
                {Multiple citation on page \thepage: same authors and
                year\MessageBreak without distinguishing extra
                letter,\MessageBreak appears as question mark}\fi
                \NAT@hyper@{\NAT@exlab}%
              \else\unskip\NAT@spacechar
                \NAT@hyper@{\NAT@date}%
              \fi
          \else
            \@citea\NAT@hyper@{%
              \NAT@nmfmt{\NAT@nm}%
              \hyper@natlinkbreak{%
                \NAT@aysep\NAT@spacechar}{\@citeb\@extra@b@citeb
              }%
              \NAT@date
            }%
          \fi
        \fi
      \or\@citea\NAT@hyper@{\NAT@nmfmt{\NAT@nm}}%
      \or\@citea\NAT@hyper@{\NAT@date}%
      \or\@citea\NAT@hyper@{\NAT@alias}%
      \fi \NAT@def@citea
      \else
        \ifcase\NAT@ctype
          \if\relax\NAT@date\relax
            \@citea\NAT@hyper@{\NAT@nmfmt{\NAT@nm}}%
          \else
          \ifx\NAT@last@nm\NAT@nm\NAT@yrsep
              \ifx\NAT@last@yr\NAT@year
                \def\NAT@temp{{?}}%
                \ifx\NAT@temp\NAT@exlab\PackageWarningNoLine{natbib}%
                {Multiple citation on page \thepage: same authors and
                year\MessageBreak without distinguishing extra
                letter,\MessageBreak appears as question mark}\fi
                \NAT@hyper@{\NAT@exlab}%
              \else
                \unskip\NAT@spacechar
                \NAT@hyper@{\NAT@date}%
              \fi
          \else
            \@citea\NAT@hyper@{%
              \NAT@nmfmt{\NAT@nm}%
              \hyper@natlinkbreak{\NAT@spacechar\NAT@@open\if*#1*\else#1\NAT@spacechar\fi}%
                {\@citeb\@extra@b@citeb}%
              \NAT@date
            }%
          \fi
          \fi
        \or\@citea\NAT@hyper@{\NAT@nmfmt{\NAT@nm}}%
        \or\@citea\NAT@hyper@{\NAT@date}%
        \or\@citea\NAT@hyper@{\NAT@alias}%
        \fi
        \if\relax\NAT@date\relax
          \NAT@def@citea
        \else
          \NAT@def@citea@close
        \fi
      \fi
      }}\ifNAT@swa\else
        % 将 author-year 式 \cs{citet} 引用的页码置于括号外并改为上标。
        %
        % \if*#2*\else\NAT@cmt#2\fi
        \if\relax\NAT@date\relax\else\NAT@@close\fi
        \if*#2*\else\textsuperscript{#2}\fi
      \fi}{#1}{#2}}
  %
  % 为了将参考文献加入目录和 pdf 书签，重新定义 \pkg{natbib} 的 \cmd{bibsection}
  % 另外如果调用了 \pkg{chapterbib} 或者使用了 \opt{sectionbib} 参数，
  % 需要使用节标题 \cs{section}。
  \newcommand\cust@bib@chapter{%
    \@mainmatterfalse
    \chapter{\bibname}%
  }%
  \newcommand\cust@bib@section{%
    \begingroup
      \ctexset{section/numbering=false}%
      \section{\bibname}%
    \endgroup
  }%
  \@ifpackagewith{chapterbib}{sectionbib}{%
    \cust@error{The "sectionbib" option cannot be used with chaperbib if natbib loaded}%
  }{}%
  \@ifpackageloaded{chapterbib}{%
    \let\bibsection\cust@bib@section
  }{%
    \@ifxundefined\NAT@sectionbib{%
      \let\bibsection\cust@bib@chapter
    }{%
      \let\bibsection\cust@bib@section
    }%
  }%
  %
  % 参考文献列表格式：宋体 10.5 磅，行距 20 磅，续行缩进两字，左对齐。
  % 本科生依然是小四宋体。
  \renewcommand\bibfont{%
    \ifcust@degree@graduate
      \fontsize{10.5bp}{20bp}\selectfont
    \else
      \normalsize
    \fi
  }
  \setlength{\bibsep}{0\p@ \@plus.2\p@}
  \renewcommand\@biblabel[1]{[#1]\hfill}
  \setlength{\bibhang}{2\ccwd}
}


% biblatex 宏包的配置

\AtEndOfPackageFile*{biblatex}{
  \DeclareRobustCommand\inlinecite{\parencite}
  \defbibheading{bibliography}[\bibname]{%
    \@mainmatterfalse
    \chapter{\bibname}%
  }
  \renewcommand\bibfont{%
    \ifcust@degree@graduate
      \fontsize{10.5bp}{20bp}\selectfont
    \else
      \normalsize
    \fi
  }
  \setlength{\bibitemsep}{0\p@ \@plus.2\p@}
  \setlength{\bibhang}{2\ccwd}
}

% \subsection{附录}

% 定义了一个满足要求的致谢环境：
\newenvironment{acknowledgements}{%
  \@mainmatterfalse
  \chapter{\cust@acknowledgements@name}%
}{
%  \ifcust@degree@bachelor
    \par
    \null\par
    \begingroup
      \raggedleft
      \href{https://www.cvirlab.com}
      {校光电测试分析中心CVIR实验室}\par%如果致谢部分不需要落款名字，可以注释掉
%      \cust@author\par %如果致谢部分不需要落款名字，可以注释掉
      \cust@date@zh@short\par  %如果致谢部分不需要添加时间，可以注释掉
    \endgroup
%  \fi
}


% 兼容旧版本中“acknowledgments”的拼法。
% Reserved for compatibility until 2020-07-01.
\newenvironment{acknowledgments}{%
  \begin{acknowledgements}%
}{%
  \end{acknowledgements}%
}

% 发表成果环境：
\newenvironment{publications}{%
  \@mainmatterfalse
  \chapter{\cust@publication@name}%
}{}


% \subsection{其他宏包的设置}

% 这些宏包并非格式要求，但是为了方便同学们使用，在这里进行简单设置。


% \subsubsection{\pkg{hyperref} 宏包}

\AtEndOfPackageFile*{hyperref}{
  \hypersetup{
    bookmarksnumbered  = true,
    bookmarksopen      = true,
    bookmarksopenlevel = 1,
    linktoc            = all,
    unicode            = true,
    psdextra           = true,
  }
  %
  % 如果为 \opt{pdf} 样式，设置 hyperlink 颜色
  \ifcust@output@electronic
    \hypersetup{
      colorlinks = true,
      allcolors  = blue,
    }
  \else
    \hypersetup{hidelinks}
  \fi
  %
  % 填写 PDF 元信息。
  \AtBeginDocument{%
    \ifcust@main@language@chinese
      \hypersetup{
        pdftitle  = \cust@title,
        pdfauthor = \cust@author,
      }%
    \else
      \hypersetup{
        pdftitle  = \cust@title@en,
        pdfauthor = \cust@author@en,
      }%
    \fi
  }
  %
  % 添加 PDF 书签
  %
  \newcounter{cust@bookmarknumber}
  \renewcommand\cust@pdfbookmark[1]{%
    \phantomsection
    \stepcounter{cust@bookmarknumber}%
    \pdfbookmark[0]{#1}{custchapter.\thecust@bookmarknumber}%
  }
  %
  % 在 PDF 字符串中去掉换行，以减少 \pkg{hyperref} 的警告信息。
  \pdfstringdefDisableCommands{
    \let\\\@empty
    \let\hspace\@gobble
  }
  %
  % \pkg{hyperref} 与 \pkg{unicode-math} 存在一些兼容性问题，见
  % \href{https://github.com/custtug/custhesis/issues/223}{%
  %   custtug/custhesis\#223}，
  % \href{https://github.com/ho-tex/hyperref/pull/90}{ho-tex/hyperref\#90} 和
  % \href{https://github.com/custtug/custhesis/issues/235}{%
  %   custtug/custhesis/\#235}。
  \@ifpackagelater{hyperref}{2019/04/27}{}{%
    \g@addto@macro\psdmapshortnames{\let\mu\textmu}%
  }
  %
  % 设置中文的 \cs{autoref}。
  % \footnote{\url{https://tex.stackexchange.com/a/66150/82731}}
  \ifcust@language@chinese
    \def\equationautorefname~#1\null{公式~(#1)\null}
    \def\footnoteautorefname{脚注}
    \def\itemautorefname~#1\null{第~#1~项\null}
    \def\figureautorefname{图}
    \def\tableautorefname{表}
    \def\partautorefname~#1\null{第~#1~部分\null}
    \def\appendixautorefname{附录}
    \def\chapterautorefname~#1\null{第~#1~章\null}
    \def\sectionautorefname~#1\null{第~#1~节\null}
    \def\subsectionautorefname~#1\null{第~#1~小节\null}
    \def\subsubsectionautorefname~#1\null{第~#1~小小节\null}
    \def\paragraphautorefname~#1\null{第~#1~段\null}
    \def\subparagraphautorefname~#1\null{第~#1~小段\null}
%    \def\subsubparagraphautorefname~#1\null{第~#1~款\null}
    \def\theoremautorefname{定理}
    \def\HyRef@autopageref#1{\hyperref[{#1}]{第~\pageref*{#1} 页}}
  \fi
  %
  % 本科生需要在 \tableofcontents 处切换 \pagenumbering，
  % 在使用了 notoccite 后会导致 PDF 书签的页码有误（#293），
  % 所以需要补充 https://tex.stackexchange.com/a/593839/82731 的 patch。
  % LuaTeX 不需要这个 patch。
  \ifXeTeX
    \def\HyPL@StorePageLabel#1{%
      \begingroup
        \edef\Hy@tempa{\the\Hy@abspage<<#1>>}%
        \immediate\write\@mainaux{%
          \string\HyPL@Entry{\Hy@tempa}%
        }%
      \endgroup
    }
  \fi
}


% \subsubsection{\pkg{amsthm} 宏包}

\AtEndOfPackageFile*{amsthm}{
  \newtheoremstyle{custplain}
    {}{}
    {}{2\ccwd}
    {\bfseries}{}
    {\ccwd}{}
  \theoremstyle{custplain}
  % 定义新的定理
  \ifcust@language@chinese
    \newcommand\cust@assertion@name{断言}
    \newcommand\cust@assumption@name{假设}
    \newcommand\cust@axiom@name{公理}
    \newcommand\cust@corollary@name{推论}
    \newcommand\cust@definition@name{定义}
    \newcommand\cust@example@name{例}
    \newcommand\cust@lemma@name{引理}
    \newcommand\cust@proof@name{证明}
    \newcommand\cust@proposition@name{命题}
    \newcommand\cust@remark@name{注}
    \newcommand\cust@theorem@name{定理}
  \else
    \newcommand\cust@assertion@name{Assertion}
    \newcommand\cust@assumption@name{Assumption}
    \newcommand\cust@axiom@name{Axiom}
    \newcommand\cust@corollary@name{Corollary}
    \newcommand\cust@definition@name{Definition}
    \newcommand\cust@example@name{Example}
    \newcommand\cust@lemma@name{Lemma}
    \newcommand\cust@proof@name{Proof}
    \newcommand\cust@proposition@name{Proposition}
    \newcommand\cust@remark@name{Remark}
    \newcommand\cust@theorem@name{Theorem}
  \fi
  \newtheorem{theorem}             {\cust@theorem@name}    [chapter]
  \newtheorem{assertion}  [theorem]{\cust@assertion@name}
  \newtheorem{axiom}      [theorem]{\cust@axiom@name}
  \newtheorem{corollary}  [theorem]{\cust@corollary@name}
  \newtheorem{lemma}      [theorem]{\cust@lemma@name}
  \newtheorem{proposition}[theorem]{\cust@proposition@name}
  \newtheorem{assumption}          {\cust@assumption@name} [chapter]
  \newtheorem{definition}          {\cust@definition@name} [chapter]
  \newtheorem{example}             {\cust@example@name}    [chapter]
  \newtheorem*{remark}             {\cust@remark@name}
  % \pkg{amsthm} 单独定义了 proof 环境，这里重新定义以满足格式要求。
  % 原本模仿 \pkg{amsthm} 写成 |\item[\hskip\labelsep\hskip2\ccwd #1\hskip\ccwd]|，
  % 但是却会多出一些间隙。
  \renewenvironment{proof}[1][\cust@proof@name]{\par
    \pushQED{\qed}%
    \normalfont \topsep6\p@\@plus6\p@\relax
    \trivlist
      \item\relax\hskip2\ccwd
      \textbf{#1}
      \hskip\ccwd\ignorespaces
    }{%
    \popQED\endtrivlist\@endpefalse
  }
  \renewcommand\qedsymbol{\cust@qed}
}


% \subsubsection{\pkg{algorithm2e} 宏包}

% 按章节编号。
\PassOptionsToPackage{algochapter}{algorithm2e}

\AtEndOfPackageFile*{algorithm2e}{
  \ifcust@language@chinese
    \SetAlgorithmName{算法}{算法}{算法清单}
  \else
    \SetAlgorithmName{Algorithm}{Algorithm}{List of Algorithms}
  \fi
  %
  % 设置算法环境的格式。
  \SetAlCapSkip{6bp}
  \SetAlCapFnt{\small}
  \SetAlCapNameFnt{\small}
  \ifcust@degree@graduate
    \SetAlCapNameSty{textbf}
  \fi
  \SetAlgoCaptionSeparator{\unskip\hspace*{\ccwd}}
  %
  % 设置算法清单的格式
  \renewcommand\listofalgocfs{%
    \ifcust@degree@graduate
      \cleardoublepage
    \fi
    \cust@chapter{\listalgorithmcfname}%
    \@starttoc{loa}%
  }
  \titlecontents{algocf}
    [2.3em]{\normalsize}
    {\contentslabel{2.3em}}{}
    {\cust@leaders\contentspage}
  \contentsuse{algocf}{loa}
}


% \subsubsection{\pkg{mathtools} 宏包}

% \pkg{mathtools} 会修改 \pkg{unicode-math} 的 `\underbrace` 和 `\overbrace`，
% 需要还原为 `\LaTeXunderbrace` 和 `\LaTeXoverbrace`，
% 参考 \url{https://tex.stackexchange.com/q/521394/82731}。
\AtEndOfPackageFile*{mathtools}{
  \@ifpackageloaded{unicode-math}{
    \let\underbrace\LaTeXunderbrace
    \let\overbrace\LaTeXoverbrace
  }{}
}

% \subsubsection{\pkg{nomencl} 宏包}

\AtEndOfPackageFile*{nomencl}{
  \let\nomname\cust@notation@name
  \def\thenomenclature{%
    \ifcust@degree@graduate
      \cleardoublepage
      \pagestyle{headings}%
    \fi
    \cust@chapter{\cust@notation@name}%
    \nompreamble
    \list{}{%
      \labelwidth\nom@tempdim
      \leftmargin\labelwidth
      \advance\leftmargin\labelsep
      \itemsep\nomitemsep
      \let\makelabel\nomlabel}}
  \def\endthenomenclature{%
    \endlist
    \nompostamble
    \ifcust@degree@graduate
      \clearpage
      \pagestyle{plain}%
    \fi
  }
}


% \subsubsection{\pkg{siunitx} 宏包}

\AtEndOfPackageFile*{siunitx}{
  \newcommand\cust@set@siunitx@language{%
    \ifcust@language@chinese
      \sisetup{
        list-final-separator = { 和~},
        list-pair-separator  = { 和 },
        range-phrase         = {～},
      }%
    \else
      \sisetup{
        list-final-separator = {, and },
        list-pair-separator  = { and },
        range-phrase         = { to },
      }%
    \fi
  }
  \cust@set@siunitx@language
  \cust@option@hook{language}{\cust@set@siunitx@language}
}

% \subsubsection{\pkg{chapterbib} 宏包}

\AtEndOfPackageFile*{chapterbib}{
  \@ifpackageloaded{natbib}{%
    \@ifpackagewith{chapterbib}{sectionbib}{%
      \cust@error{The "sectionbib" option cannot be used with chaperbib if natbib loaded}%
    }{}%
    \renewcommand\bibsection{%
      \begingroup
        \ctexset{section/numbering=false}%
        \section{\bibname}%
      \endgroup
    }
  }{}
}
