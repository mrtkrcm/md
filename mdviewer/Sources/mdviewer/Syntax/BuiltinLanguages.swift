//
//  BuiltinLanguages.swift
//  mdviewer
//

#if os(macOS)
    internal import Foundation

    // MARK: - Swift

    extension LanguageRegistry {
        static let swift = LanguageDefinition(
            id: "swift",
            name: "Swift",
            aliases: ["swift"],
            patterns: SyntaxPatterns(
                keywords: try? NSRegularExpression(
                    pattern: #"\b(let|var|func|struct|class|enum|protocol|extension|import|if|else|for|while|guard|switch|case|default|return|throw|throws|try|catch|in|where|async|await|actor|defer|do|repeat|break|continue|fallthrough|typealias|associatedtype|some|any|mutating|nonmutating|init|deinit|subscript|static|final|private|fileprivate|internal|public|open|lazy|weak|unowned|required|convenience|dynamic|optional|override|self|Self|super|true|false|nil)\b"#
                ),
                strings: try? NSRegularExpression(pattern: #""([^"\\]|\\.)*"|"""[^"]*""""#),
                lineComments: try? NSRegularExpression(pattern: #"//.*$"#, options: [.anchorsMatchLines]),
                blockComments: try? NSRegularExpression(pattern: #"/\*[\s\S]*?\*/"#),
                numbers: try? NSRegularExpression(
                    pattern: #"\b(0x[0-9A-Fa-f]+(?:\.[0-9A-Fa-f]+)?p[+-]?\d+|0b[01]+|0o[0-7]+|[0-9]+(?:\.[0-9]+)?(?:e[+-]?[0-9]+)?)\b"#
                ),
                types: try? NSRegularExpression(pattern: #"\b([A-Z][A-Za-z0-9_]*)\b"#),
                calls: try? NSRegularExpression(pattern: #"\b([a-zA-Z_][A-Za-z0-9_]*)\s*(?=\()"#),
                properties: try? NSRegularExpression(pattern: #"\.(\w+)"#),
                operators: try? NSRegularExpression(
                    pattern: #"(\+|-|\*|/|%|==|!=|<=|>=|<|>|&&|\|\||!|\?|:|\+\+|--|\+=|-=|\*=|/=|%=|&|\||\^|~|<<|>>)"#
                )
            )
        )
    }

    // MARK: - JavaScript

    extension LanguageRegistry {
        static let javascript = LanguageDefinition(
            id: "javascript",
            name: "JavaScript",
            aliases: ["javascript", "js", "jsx", "node", "nodejs"],
            patterns: SyntaxPatterns(
                keywords: try? NSRegularExpression(
                    pattern: #"\b(const|let|var|function|class|extends|super|static|import|export|from|default|as|async|await|return|if|else|for|while|do|switch|case|break|continue|default|throw|try|catch|finally|new|this|typeof|instanceof|void|delete|in|of|with|yield|debugger|true|false|null|undefined)\b"#
                ),
                strings: try? NSRegularExpression(pattern: #"'([^'\\]|\\.)*'|"([^"\\]|\\.)*"|`([^`\\]|\\.)*`"#),
                lineComments: try? NSRegularExpression(pattern: #"//.*$"#, options: [.anchorsMatchLines]),
                blockComments: try? NSRegularExpression(pattern: #"/\*[\s\S]*?\*/"#),
                numbers: try? NSRegularExpression(
                    pattern: #"\b(0x[0-9A-Fa-f]+|0b[01]+|0o[0-7]+|[0-9]+(?:\.[0-9]+)?(?:e[+-]?[0-9]+)?)\b"#
                ),
                types: try? NSRegularExpression(pattern: #"\b([A-Z][A-Za-z0-9_$]*)\b"#),
                calls: try? NSRegularExpression(pattern: #"\b([a-zA-Z_$][A-Za-z0-9_$]*)\s*(?=\()"#),
                properties: try? NSRegularExpression(pattern: #"\.(\w+)"#),
                operators: try? NSRegularExpression(
                    pattern: #"(=>|===|!==|==|!=|<=|>=|\+\+|--|&&|\|\||\+|-|\*|/|%|<|>|!|\?|:|\.|,)"#
                )
            )
        )
    }

    // MARK: - TypeScript

    extension LanguageRegistry {
        static let typescript = LanguageDefinition(
            id: "typescript",
            name: "TypeScript",
            aliases: ["typescript", "ts", "tsx"],
            patterns: SyntaxPatterns(
                keywords: try? NSRegularExpression(
                    pattern: #"\b(const|let|var|function|class|extends|super|static|import|export|from|default|as|async|await|return|if|else|for|while|do|switch|case|break|continue|default|throw|try|catch|finally|new|this|typeof|instanceof|void|delete|in|of|with|yield|debugger|true|false|null|undefined|interface|type|namespace|module|declare|abstract|readonly|private|protected|public|get|set|implements|enum)\b"#
                ),
                strings: try? NSRegularExpression(pattern: #"'([^'\\]|\\.)*'|"([^"\\]|\\.)*"|`([^`\\]|\\.)*`"#),
                lineComments: try? NSRegularExpression(pattern: #"//.*$"#, options: [.anchorsMatchLines]),
                blockComments: try? NSRegularExpression(pattern: #"/\*[\s\S]*?\*/"#),
                numbers: try? NSRegularExpression(
                    pattern: #"\b(0x[0-9A-Fa-f]+|0b[01]+|0o[0-7]+|[0-9]+(?:\.[0-9]+)?(?:e[+-]?[0-9]+)?)\b"#
                ),
                types: try? NSRegularExpression(pattern: #"\b([A-Z][A-Za-z0-9_$]*)\b"#),
                calls: try? NSRegularExpression(pattern: #"\b([a-zA-Z_$][A-Za-z0-9_$]*)\s*(?=\()"#),
                properties: try? NSRegularExpression(pattern: #"\.(\w+)"#),
                operators: try? NSRegularExpression(
                    pattern: #"(=>|===|!==|==|!=|<=|>=|\+\+|--|&&|\|\||\+|-|\*|/|%|<|>|!|\?|:|\.|,)"#
                )
            )
        )
    }

    // MARK: - Python

    extension LanguageRegistry {
        static let python = LanguageDefinition(
            id: "python",
            name: "Python",
            aliases: ["python", "py", "python3", "py3"],
            patterns: SyntaxPatterns(
                keywords: try? NSRegularExpression(
                    pattern: #"\b(and|as|assert|async|await|break|class|continue|def|del|elif|else|except|finally|for|from|global|if|import|in|is|lambda|nonlocal|not|or|pass|raise|return|try|while|with|yield|None|True|False|print)\b"#
                ),
                strings: try? NSRegularExpression(
                    pattern: #"'([^'\\]|\\.)*'|"([^"\\]|\\.)*"|'''[\s\S]*?'''|"""[\s\S]*?""""#
                ),
                lineComments: try? NSRegularExpression(pattern: #"#.*$"#, options: [.anchorsMatchLines]),
                blockComments: nil,
                numbers: try? NSRegularExpression(
                    pattern: #"\b(0x[0-9A-Fa-f]+|0b[01]+|0o[0-7]+|[0-9]+(?:\.[0-9]+)?(?:e[+-]?[0-9]+)?j?)\b"#
                ),
                types: try? NSRegularExpression(pattern: #"\b([A-Z][A-Za-z0-9_]*)\b"#),
                calls: try? NSRegularExpression(pattern: #"\b([a-zA-Z_][A-Za-z0-9_]*)\s*(?=\()"#),
                properties: try? NSRegularExpression(pattern: #"\.(\w+)"#),
                operators: try? NSRegularExpression(
                    pattern: #"(\+|-|\*|/|%|\*\*|//|==|!=|<>|>|<|>=|<=|=|\+=|-=|\*=|/=|//=|%=|\*\*=|&|\||\^|~|<<|>>|and|or|not|in|is)"#
                )
            )
        )
    }

    // MARK: - JSON

    extension LanguageRegistry {
        static let json = LanguageDefinition(
            id: "json",
            name: "JSON",
            aliases: ["json"],
            patterns: SyntaxPatterns(
                keywords: try? NSRegularExpression(pattern: #"\b(true|false|null)\b"#),
                strings: try? NSRegularExpression(pattern: #""([^"\\]|\\.)*""#),
                lineComments: nil,
                blockComments: nil,
                numbers: try? NSRegularExpression(pattern: #"(-?[0-9]+(?:\.[0-9]+)?(?:e[+-]?[0-9]+)?)"#),
                types: nil,
                calls: nil,
                properties: try? NSRegularExpression(pattern: #""(\w+)"\s*:"#),
                operators: try? NSRegularExpression(pattern: #"(:|,|\{|\}|\[|\])"#)
            )
        )
    }

    // MARK: - HTML

    extension LanguageRegistry {
        static let html = LanguageDefinition(
            id: "html",
            name: "HTML",
            aliases: ["html", "htm", "xhtml"],
            patterns: SyntaxPatterns(
                keywords: try? NSRegularExpression(
                    pattern: #"\b(doctype|html|head|body|script|style|link|meta|title|div|span|p|a|img|ul|ol|li|table|tr|td|th|thead|tbody|tfoot|form|input|button|select|option|textarea|label|h1|h2|h3|h4|h5|h6|br|hr|em|strong|b|i|u|code|pre|blockquote|nav|header|footer|main|section|article|aside|figure|figcaption)\b"#,
                    options: .caseInsensitive
                ),
                strings: try? NSRegularExpression(pattern: #""([^"]*?)"|'([^']*?)'"#),
                lineComments: try? NSRegularExpression(pattern: #"<!--.*$"#, options: [.anchorsMatchLines]),
                blockComments: try? NSRegularExpression(pattern: #"<!--[\s\S]*?-->"#),
                numbers: try? NSRegularExpression(pattern: #"\b\d+\b"#),
                types: nil,
                calls: nil,
                properties: try? NSRegularExpression(pattern: #"\s(\w+)=\""#),
                operators: try? NSRegularExpression(pattern: #"(</?|>|/|<!--|--)"#)
            )
        )
    }

    // MARK: - CSS

    extension LanguageRegistry {
        static let css = LanguageDefinition(
            id: "css",
            name: "CSS",
            aliases: ["css", "scss", "sass", "less"],
            patterns: SyntaxPatterns(
                keywords: try? NSRegularExpression(
                    pattern: #"\b(display|position|width|height|margin|padding|border|color|background|font|text|overflow|float|clear|visibility|opacity|z-index|top|left|right|bottom|content|cursor|transform|transition|animation|flex|grid)\b"#,
                    options: .caseInsensitive
                ),
                strings: try? NSRegularExpression(pattern: #""([^"\\]|\\.)*"|'([^'\\]|\\.)*'"#),
                lineComments: try? NSRegularExpression(pattern: #"//.*$"#, options: [.anchorsMatchLines]),
                blockComments: try? NSRegularExpression(pattern: #"/\*[\s\S]*?\*/"#),
                numbers: try? NSRegularExpression(
                    pattern: #"(-?[0-9]+(?:\.[0-9]+)?(?:px|em|rem|%|vh|vw|pt|pc|in|cm|mm|ex|ch|vmin|vmax|s|ms)?)\b"#,
                    options: .caseInsensitive
                ),
                types: try? NSRegularExpression(pattern: #"\b([A-Z][A-Za-z0-9]*)\b"#),
                calls: try? NSRegularExpression(pattern: #"([a-zA-Z-]+)\s*(?=\()"#),
                properties: try? NSRegularExpression(pattern: #"([a-zA-Z-]+)\s*:"#),
                operators: try? NSRegularExpression(pattern: #"(:|;|\{|\}|,|\.|#|\[|\]|::|\+)"#)
            )
        )
    }

    // MARK: - Bash/Shell

    extension LanguageRegistry {
        static let bash = LanguageDefinition(
            id: "bash",
            name: "Bash",
            aliases: ["bash", "sh", "shell", "zsh", "fish", "cmd", "powershell", "ps1", "pwsh"],
            patterns: SyntaxPatterns(
                keywords: try? NSRegularExpression(
                    pattern: #"\b(if|then|else|elif|fi|for|while|do|done|case|esac|in|function|return|exit|export|source|alias|echo|printf|read|cd|pwd|ls|cat|grep|sed|awk|chmod|chown|mkdir|rm|cp|mv|tar|gzip|curl|wget|ssh|sudo)\b"#
                ),
                strings: try? NSRegularExpression(pattern: #"'[^']*'|"([^"\\]|\\.)*"|\$'[^']*'"#),
                lineComments: try? NSRegularExpression(pattern: #"#.*$"#, options: [.anchorsMatchLines]),
                blockComments: nil,
                numbers: try? NSRegularExpression(pattern: #"\b[0-9]+\b"#),
                types: nil,
                calls: try? NSRegularExpression(pattern: #"\b([a-zA-Z_][a-zA-Z0-9_]*)\s+(?![=])"#),
                properties: try? NSRegularExpression(pattern: #"\$(\w+|\{[^}]+\}|\d+)"#),
                operators: try? NSRegularExpression(
                    pattern: #"(\|\||\|&&|&|;|\|\||\|>|>|>>|<|<<|=|!=|==|\+|-|\*|/|%|!)"#
                )
            )
        )
    }

    // MARK: - SQL

    extension LanguageRegistry {
        static let sql = LanguageDefinition(
            id: "sql",
            name: "SQL",
            aliases: ["sql", "mysql", "postgresql", "postgres", "sqlite", "mssql", "oracle"],
            patterns: SyntaxPatterns(
                keywords: try? NSRegularExpression(
                    pattern: #"\b(SELECT|INSERT|UPDATE|DELETE|FROM|WHERE|JOIN|LEFT|RIGHT|INNER|OUTER|FULL|CROSS|NATURAL|ON|GROUP|BY|ORDER|HAVING|LIMIT|OFFSET|UNION|ALL|DISTINCT|AS|AND|OR|NOT|NULL|IS|IN|BETWEEN|LIKE|EXISTS|CASE|WHEN|THEN|ELSE|END|IF|CREATE|TABLE|VIEW|INDEX|DROP|ALTER|ADD|COLUMN|CONSTRAINT|PRIMARY|KEY|FOREIGN|REFERENCES|DEFAULT|UNIQUE|CHECK|VALUES|INTO|SET|BEGIN|COMMIT|ROLLBACK|TRANSACTION)\b"#,
                    options: .caseInsensitive
                ),
                strings: try? NSRegularExpression(pattern: #"'([^']|'')*'|"([^"\\]|\\.)*""#),
                lineComments: try? NSRegularExpression(pattern: #"--.*$"#, options: [.anchorsMatchLines]),
                blockComments: try? NSRegularExpression(pattern: #"/\*[\s\S]*?\*/"#),
                numbers: try? NSRegularExpression(pattern: #"\b[0-9]+(?:\.[0-9]+)?\b"#),
                types: nil,
                calls: try? NSRegularExpression(
                    pattern: #"\b([a-zA-Z_][a-zA-Z0-9_]*)\s*(?=\()"#,
                    options: .caseInsensitive
                ),
                properties: try? NSRegularExpression(pattern: #"\b([a-zA-Z_][a-zA-Z0-9_]*)\.([a-zA-Z_][a-zA-Z0-9_]*)"#),
                operators: try? NSRegularExpression(pattern: #"(=|!=|<>|<|>|<=|>=|\+|-|\*|/|%|\|\||::)"#)
            )
        )
    }

    // MARK: - Rust

    extension LanguageRegistry {
        static let rust = LanguageDefinition(
            id: "rust",
            name: "Rust",
            aliases: ["rust", "rs"],
            patterns: SyntaxPatterns(
                keywords: try? NSRegularExpression(
                    pattern: #"\b(let|mut|fn|struct|enum|impl|trait|type|const|static|use|mod|pub|crate|super|self|Self|if|else|match|loop|while|for|in|break|continue|return|async|await|move|where|unsafe|async|await|dyn|ref|box|as|move|true|false|None|Some|Ok|Err)\b"#
                ),
                strings: try? NSRegularExpression(pattern: #""([^"\\]|\\.)*"|b"([^"\\]|\\.)*""#),
                lineComments: try? NSRegularExpression(pattern: #"//.*(/!)?.*$"#, options: [.anchorsMatchLines]),
                blockComments: try? NSRegularExpression(pattern: #"/\*[\s\S]*?\*/"#),
                numbers: try? NSRegularExpression(
                    pattern: #"\b(0x[0-9A-Fa-f]+|0b[01]+|0o[0-7]+|[0-9]+(?:\.[0-9]+)?(?:e[+-]?[0-9]+)?)\b"#
                ),
                types: try? NSRegularExpression(pattern: #"\b([A-Z][A-Za-z0-9_]*)\b"#),
                calls: try? NSRegularExpression(pattern: #"\b([a-zA-Z_][A-Za-z0-9_]*)\s*(?=\()"#),
                properties: try? NSRegularExpression(pattern: #"\.(\w+)"#),
                operators: try? NSRegularExpression(
                    pattern: #"(\+|-|\*|/|%|==|!=|<=|>=|<|>|&&|\|\||!|\?|:|\+\+|--|\+=|-=|\*=|/=|%=|&|\||\^|~|<<|>>|->|=>)"#
                )
            )
        )
    }

    // MARK: - Go

    extension LanguageRegistry {
        static let go = LanguageDefinition(
            id: "go",
            name: "Go",
            aliases: ["go", "golang"],
            patterns: SyntaxPatterns(
                keywords: try? NSRegularExpression(
                    pattern: #"\b(package|import|func|var|const|type|struct|interface|map|chan|go|defer|return|if|else|for|range|switch|case|default|break|continue|goto|fallthrough|select|true|false|nil|iota|make|new|len|cap|append|copy|close|delete|panic|recover)\b"#
                ),
                strings: try? NSRegularExpression(pattern: #"`[^`]*`|"([^"\\]|\\.)*""#),
                lineComments: try? NSRegularExpression(pattern: #"//.*$"#, options: [.anchorsMatchLines]),
                blockComments: try? NSRegularExpression(pattern: #"/\*[\s\S]*?\*/"#),
                numbers: try? NSRegularExpression(
                    pattern: #"\b(0x[0-9A-Fa-f]+|0[0-7]*|[0-9]+(?:\.[0-9]+)?(?:e[+-]?[0-9]+)?i?)\b"#
                ),
                types: try? NSRegularExpression(pattern: #"\b([A-Z][A-Za-z0-9_]*)\b"#),
                calls: try? NSRegularExpression(pattern: #"\b([a-zA-Z_][A-Za-z0-9_]*)\s*(?=\()"#),
                properties: try? NSRegularExpression(pattern: #"\.(\w+)"#),
                operators: try? NSRegularExpression(
                    pattern: #"(\+|-|\*|/|%|==|!=|<=|>=|<|>|&&|\|\||!|\?|:|\+\+|--|\+=|-=|\*=|/=|%=|&|\||\^|~|<<|>>|<-|=)"#
                )
            )
        )
    }

    // MARK: - Ruby

    extension LanguageRegistry {
        static let ruby = LanguageDefinition(
            id: "ruby",
            name: "Ruby",
            aliases: ["ruby", "rb"],
            patterns: SyntaxPatterns(
                keywords: try? NSRegularExpression(
                    pattern: #"\b(alias|and|begin|break|case|class|def|defined|do|else|elsif|end|ensure|false|for|if|in|module|next|nil|not|or|redo|rescue|retry|return|self|super|then|true|undef|unless|until|when|while|yield|__FILE__|__LINE__|__END__|__ENCODING__)\b"#
                ),
                strings: try? NSRegularExpression(pattern: #"'[^']*'|"([^"\\]|\\.)*"|%q\{[^}]*\}|%Q\{[^}]*\}"#),
                lineComments: try? NSRegularExpression(pattern: #"#.*$"#, options: [.anchorsMatchLines]),
                blockComments: try? NSRegularExpression(pattern: #"=begin[\s\S]*?=end"#),
                numbers: try? NSRegularExpression(
                    pattern: #"\b(0x[0-9A-Fa-f]+|0b[01]+|0[0-7]*|[0-9]+(?:\.[0-9]+)?(?:e[+-]?[0-9]+)?)\b"#
                ),
                types: try? NSRegularExpression(pattern: #"\b([A-Z][A-Za-z0-9_]*)\b"#),
                calls: try? NSRegularExpression(pattern: #"\b([a-zA-Z_][A-Za-z0-9_]*)\s*(?=[\(\{])"#),
                properties: try? NSRegularExpression(pattern: #"@\w+|@@\w+"#),
                operators: try? NSRegularExpression(
                    pattern: #"(=~|!~|==|===|!=|=<|=>|..<|..|<=>|\+|-|\*|/|%|\*\*|&|||\^|~|<<|>>|&&|\|\||!|~=|\+=|-=|\*=|/=|%=|\*\*=|&=||=|\^=|<<=|>>=|&&=|\|\|=)"#
                )
            )
        )
    }

    // MARK: - Java

    extension LanguageRegistry {
        static let java = LanguageDefinition(
            id: "java",
            name: "Java",
            aliases: ["java"],
            patterns: SyntaxPatterns(
                keywords: try? NSRegularExpression(
                    pattern: #"\b(abstract|assert|boolean|break|byte|case|catch|char|class|const|continue|default|do|double|else|enum|extends|final|finally|float|for|if|goto|implements|import|instanceof|int|interface|long|native|new|package|private|protected|public|return|short|static|strictfp|super|switch|synchronized|this|throw|throws|transient|try|void|volatile|while|true|false|null)\b"#
                ),
                strings: try? NSRegularExpression(pattern: #""([^"\\]|\\.)*"|"""[\s\S]*?""""#),
                lineComments: try? NSRegularExpression(pattern: #"//.*$"#, options: [.anchorsMatchLines]),
                blockComments: try? NSRegularExpression(pattern: #"/\*[\s\S]*?\*/"#),
                numbers: try? NSRegularExpression(
                    pattern: #"\b(0x[0-9A-Fa-f]+|0[0-7]+|[0-9]+(?:\.[0-9]+)?(?:e[+-]?[0-9]+)?[fFdD]?)\b"#
                ),
                types: try? NSRegularExpression(pattern: #"\b([A-Z][A-Za-z0-9_]*)\b"#),
                calls: try? NSRegularExpression(pattern: #"\b([a-zA-Z_][A-Za-z0-9_]*)\s*(?=\()"#),
                properties: try? NSRegularExpression(pattern: #"\.(\w+)"#),
                operators: try? NSRegularExpression(
                    pattern: #"(\+|-|\*|/|%|==|!=|<=|>=|<|>|&&|\|\||!|\?|:|\+\+|--|\+=|-=|\*=|/=|%=|&|\||\^|~|<<|>>|>>>)"#
                )
            )
        )
    }

    // MARK: - C

    extension LanguageRegistry {
        static let c = LanguageDefinition(
            id: "c",
            name: "C",
            aliases: ["c"],
            patterns: SyntaxPatterns(
                keywords: try? NSRegularExpression(
                    pattern: #"\b(auto|break|case|char|const|continue|default|do|double|else|enum|extern|float|for|goto|if|inline|int|long|register|restrict|return|short|signed|sizeof|static|struct|switch|typedef|union|unsigned|void|volatile|while|_Alignas|_Alignof|_Atomic|_Bool|_Complex|_Generic|_Imaginary|_Noreturn|_Static_assert|_Thread_local)\b"#
                ),
                strings: try? NSRegularExpression(pattern: #""([^"\\]|\\.)*"|"""[^"]*""""#),
                lineComments: try? NSRegularExpression(pattern: #"//.*$"#, options: [.anchorsMatchLines]),
                blockComments: try? NSRegularExpression(pattern: #"/\*[\s\S]*?\*/"#),
                numbers: try? NSRegularExpression(
                    pattern: #"\b(0x[0-9A-Fa-f]+|0[0-7]+|[0-9]+(?:\.[0-9]+)?(?:e[+-]?[0-9]+)?[fFuUlL]?)\b"#
                ),
                types: try? NSRegularExpression(pattern: #"\b([A-Z][A-Za-z0-9_]*)\b"#),
                calls: try? NSRegularExpression(pattern: #"\b([a-zA-Z_][A-Za-z0-9_]*)\s*(?=\()"#),
                properties: try? NSRegularExpression(pattern: #"->(\w+)|\.(\w+)"#),
                operators: try? NSRegularExpression(
                    pattern: #"(\+|-|\*|/|%|==|!=|<=|>=|<|>|&&|\|\||!|\?|:|\+\+|--|\+=|-=|\*=|/=|%=|&|\||\^|~|<<|>>|->|\.)"#
                )
            )
        )
    }

    // MARK: - C++

    extension LanguageRegistry {
        static let cpp = LanguageDefinition(
            id: "cpp",
            name: "C++",
            aliases: ["cpp", "c++", "cxx", "cc"],
            patterns: SyntaxPatterns(
                keywords: try? NSRegularExpression(
                    pattern: #"\b(alignas|alignof|and|and_eq|asm|auto|bitand|bitor|bool|break|case|catch|char|char8_t|char16_t|char32_t|class|compl|concept|const|consteval|constexpr|constinit|const_cast|continue|co_await|co_return|co_yield|decltype|default|delete|do|double|dynamic_cast|else|enum|explicit|export|extern|false|float|for|friend|goto|if|inline|int|long|mutable|namespace|new|noexcept|not|not_eq|nullptr|operator|or|or_eq|private|protected|public|register|reinterpret_cast|requires|return|short|signed|sizeof|static|static_assert|static_cast|struct|switch|template|this|thread_local|throw|true|try|typedef|typeid|typename|union|unsigned|using|virtual|void|volatile|wchar_t|while|xor|xor_eq)\b"#
                ),
                strings: try? NSRegularExpression(pattern: #""([^"\\]|\\.)*"|"""[\s\S]*?"""|R\"\(([^)]|\)[^\"])*?)\""#),
                lineComments: try? NSRegularExpression(pattern: #"//.*$"#, options: [.anchorsMatchLines]),
                blockComments: try? NSRegularExpression(pattern: #"/\*[\s\S]*?\*/"#),
                numbers: try? NSRegularExpression(
                    pattern: #"\b(0x[0-9A-Fa-f]+|0b[01]+|0[0-7]+|[0-9]+(?:\.[0-9]+)?(?:e[+-]?[0-9]+)?[fFuUlL]?)\b"#
                ),
                types: try? NSRegularExpression(pattern: #"\b([A-Z][A-Za-z0-9_]*)\b"#),
                calls: try? NSRegularExpression(pattern: #"\b([a-zA-Z_][A-Za-z0-9_]*)\s*(?=\()"#),
                properties: try? NSRegularExpression(pattern: #"->(\w+)|\.(\w+)"#),
                operators: try? NSRegularExpression(
                    pattern: #"(\+|-|\*|/|%|==|!=|<=|>=|<|>|&&|\|\||!|\?|:|\+\+|--|\+=|-=|\*=|/=|%=|&|\||\^|~|<<|>>|->|\.|::|<<=|>>=)"#
                )
            )
        )
    }

    // MARK: - C#

    extension LanguageRegistry {
        static let csharp = LanguageDefinition(
            id: "csharp",
            name: "C#",
            aliases: ["csharp", "cs", "c#"],
            patterns: SyntaxPatterns(
                keywords: try? NSRegularExpression(
                    pattern: #"\b(abstract|as|base|bool|break|byte|case|catch|char|checked|class|const|continue|decimal|default|delegate|do|double|else|enum|event|explicit|extern|false|finally|fixed|float|for|foreach|goto|if|implicit|in|int|interface|internal|is|lock|long|namespace|new|null|object|operator|out|override|params|private|protected|public|readonly|ref|return|sbyte|sealed|short|sizeof|stackalloc|static|string|struct|switch|this|throw|true|try|typeof|uint|ulong|unchecked|unsafe|ushort|using|virtual|void|volatile|while|add|alias|ascending|async|await|by|descending|dynamic|equals|from|get|global|group|into|join|let|nameof|on|orderby|partial|remove|select|set|value|var|when|where|yield)\b"#
                ),
                strings: try? NSRegularExpression(pattern: #"@?"([^"\\]|\\.)*"|@?'[^']*'|"""[\s\S]*?""""#),
                lineComments: try? NSRegularExpression(pattern: #"//.*$"#, options: [.anchorsMatchLines]),
                blockComments: try? NSRegularExpression(pattern: #"/\*[\s\S]*?\*/"#),
                numbers: try? NSRegularExpression(
                    pattern: #"\b(0x[0-9A-Fa-f]+|0b[01]+|[0-9]+(?:\.[0-9]+)?(?:m|f|d|u|ul|lu|l)?)\b"#,
                    options: .caseInsensitive
                ),
                types: try? NSRegularExpression(pattern: #"\b([A-Z][A-Za-z0-9_]*)\b"#),
                calls: try? NSRegularExpression(pattern: #"\b([a-zA-Z_][A-Za-z0-9_]*)\s*(?=\()"#),
                properties: try? NSRegularExpression(pattern: #"\.(\w+)"#),
                operators: try? NSRegularExpression(
                    pattern: #"(\+|-|\*|/|%|==|!=|<=|>=|<|>|&&|\|\||!|\?|:|\+\+|--|\+=|-=|\*=|/=|%=|&|\||\^|~|<<|>>|=>|\?\?|\?\?=)"#
                )
            )
        )
    }

    // MARK: - PHP

    extension LanguageRegistry {
        static let php = LanguageDefinition(
            id: "php",
            name: "PHP",
            aliases: ["php"],
            patterns: SyntaxPatterns(
                keywords: try? NSRegularExpression(
                    pattern: #"\b(__halt_compiler|abstract|and|array|as|break|callable|case|catch|class|clone|const|continue|declare|default|die|do|echo|else|elseif|empty|enddeclare|endfor|endforeach|endif|endswitch|endwhile|eval|exit|extends|final|finally|fn|for|foreach|function|global|goto|if|implements|include|include_once|instanceof|insteadof|interface|isset|list|match|namespace|new|or|print|private|protected|public|readonly|require|require_once|return|static|switch|throw|trait|try|unset|use|var|while|xor|yield|true|false|null)\b"#
                ),
                strings: try? NSRegularExpression(pattern: #"'[^']*'|"([^"\\]|\\.)*"|"""[^"]*""""#),
                lineComments: try? NSRegularExpression(pattern: #"(#|//).*$"#, options: [.anchorsMatchLines]),
                blockComments: try? NSRegularExpression(pattern: #"/\*[\s\S]*?\*/"#),
                numbers: try? NSRegularExpression(
                    pattern: #"\b(0x[0-9A-Fa-f]+|0b[01]+|0[0-7]*|[0-9]+(?:\.[0-9]+)?(?:e[+-]?[0-9]+)?)\b"#,
                    options: .caseInsensitive
                ),
                types: try? NSRegularExpression(pattern: #"\b([A-Z][A-Za-z0-9_]*)\b"#),
                calls: try? NSRegularExpression(pattern: #"\b([a-zA-Z_][A-Za-z0-9_]*)\s*(?=\()"#),
                properties: try? NSRegularExpression(pattern: #"->(\w+)|\$\w+"#),
                operators: try? NSRegularExpression(
                    pattern: #"(\+|-|\*|/|%|\*\*|==|===|!=|!==|<>|<=|>=|<|>|&&|\|\||!|\?|:|\+\+|--|\+=|-=|\*=|/=|%=|\.=|&|\||\^|~|<<|>>|=>)"#
                )
            )
        )
    }

    // MARK: - YAML

    extension LanguageRegistry {
        static let yaml = LanguageDefinition(
            id: "yaml",
            name: "YAML",
            aliases: ["yaml", "yml"],
            patterns: SyntaxPatterns(
                keywords: try? NSRegularExpression(
                    pattern: #"\b(true|false|null|yes|no|on|off)\b"#,
                    options: .caseInsensitive
                ),
                strings: try? NSRegularExpression(pattern: #""([^"\\]|\\.)*"|'[^']*'"#),
                lineComments: try? NSRegularExpression(pattern: #"#.*$"#, options: [.anchorsMatchLines]),
                blockComments: nil,
                numbers: try? NSRegularExpression(
                    pattern: #"\b(0x[0-9A-Fa-f]+|[0-9]+(?:\.[0-9]+)?(?:e[+-]?[0-9]+)?)\b"#
                ),
                types: nil,
                calls: nil,
                properties: try? NSRegularExpression(
                    pattern: #"^\s*([a-zA-Z_][a-zA-Z0-9_]*)\s*:"#,
                    options: [.anchorsMatchLines]
                ),
                operators: try? NSRegularExpression(pattern: #"(:|-|\||>|\*|&|!|!!|!\w+)"#)
            )
        )
    }

    // MARK: - Markdown

    extension LanguageRegistry {
        static let markdown = LanguageDefinition(
            id: "markdown",
            name: "Markdown",
            aliases: ["markdown", "md", "mkd"],
            patterns: SyntaxPatterns(
                keywords: try? NSRegularExpression(
                    pattern: #"^\s*(#{1,6}|>|\s*[-*+]\s|\s*\d+\.\s|\[\!|```|\[.*?\]:|\*\*\*|___|---|\|\s*[-:]+\s*\|)"#,
                    options: [.anchorsMatchLines]
                ),
                strings: nil,
                lineComments: nil,
                blockComments: nil,
                numbers: try? NSRegularExpression(pattern: #"^\s*\d+\."#, options: [.anchorsMatchLines]),
                types: nil,
                calls: nil,
                properties: nil,
                operators: try? NSRegularExpression(pattern: #"(\*\*\*|___|---|`|\[|\]|\(|\)|!|\*|_|~~|#)"#)
            )
        )
    }

    // MARK: - XML

    extension LanguageRegistry {
        static let xml = LanguageDefinition(
            id: "xml",
            name: "XML",
            aliases: ["xml", "plist", "svg", "xhtml", "rss", "atom"],
            patterns: SyntaxPatterns(
                keywords: try? NSRegularExpression(pattern: #"\b(version|encoding|standalone|xmlns)\b"#),
                strings: try? NSRegularExpression(pattern: #""([^"]*?)"|'([^']*?)'"#),
                lineComments: try? NSRegularExpression(pattern: #"<!--.*$"#, options: [.anchorsMatchLines]),
                blockComments: try? NSRegularExpression(pattern: #"<!--[\s\S]*?-->|!<\[CDATA\[[\s\S]*?\]\]>"#),
                numbers: try? NSRegularExpression(pattern: #"\b\d+\b"#),
                types: nil,
                calls: nil,
                properties: try? NSRegularExpression(pattern: #"\s(\w+[:=])"#),
                operators: try? NSRegularExpression(pattern: #"(</?|>|/|<!--|--)"#)
            )
        )
    }
#endif
