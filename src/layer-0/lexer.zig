pub const TokenType = enum {
    left_paren,
    right_paren,
    comment,
    literal,
    string,
    error_,
    eof,
};

pub const Token = struct {
    type: TokenType,
    value: []const u8,
    start_line: usize,
    start_column: usize,
    end_line: usize,
    end_column: usize,
};

pub const Lexer = struct {
    source: []const u8,
    line: usize,
    column: usize,
    start_index: usize,
    current_index: usize,

    pub fn init(source: []const u8) Lexer {
        return .{
            .source = source,
            .line = 0,
            .column = 0,
            .start_index = 0,
            .current_index = 0,
        };
    }

    pub fn isAtEnd(self: *Lexer) bool {
        return self.current_index >= self.source.len;
    }

    fn incrLine(self: *Lexer) void {
        self.line += 1;
        self.column = 0;
    }

    fn advance(self: *Lexer) void {
        self.current_index += 1;
        self.column += 1;
        if (self.isAtEnd()) self.current_index = self.source.len;
    }

    fn peek(self: *Lexer, offset: usize) u8 {
        const index = self.current_index + offset;
        return if (index < self.source.len) self.source[index] else 0;
    }

    fn resetLength(self: *Lexer) void {
        self.start_index = self.current_index;
    }

    fn token(self: *Lexer, token_type: TokenType) Token {
        return .{
            .type = token_type,
            .value = self.source[self.start_index..self.current_index],
            .start_line = self.line,
            .start_column = self.column + self.start_index - self.current_index,
            .end_line = self.line,
            .end_column = self.column,
        };
    }

    fn multilineToken(self: *Lexer, token_type: TokenType, s_line: usize, s_col: usize) Token {
        return .{
            .type = token_type,
            .value = self.source[self.start_index..self.current_index],
            .start_line = s_line,
            .start_column = s_col,
            .end_line = self.line,
            .end_column = self.column,
        };
    }

    fn errorToken(self: *Lexer, message: []const u8) Token {
        return .{
            .type = .error_,
            .value = message,
            .start_line = self.line,
            .start_column = self.column,
            .end_line = self.line,
            .end_column = self.column,
        };
    }

    fn isLiteral(c: u8) bool {
        return switch (c) {
            ' ', '\t', '\r', '\n', '(', ')', ';', 0 => false,
            else => true,
        };
    }

    fn comment(self: *Lexer) Token {
        // discard ;
        self.resetLength();
        while (self.peek(0) != '\n' and !self.isAtEnd()) self.advance();
        return self.token(.comment);
    }

    fn literal(self: *Lexer) Token {
        while (isLiteral(self.peek(0))) self.advance();
        return self.token(.literal);
    }

    fn string(self: *Lexer) Token {
        // discard opening quote
        self.resetLength();

        const start_line = self.line;
        const start_col = self.column;

        while (self.peek(0) != '"' and !self.isAtEnd()) {
            if (self.peek(0) == '\n') self.incrLine();
            if (self.peek(0) == '\\' and self.peek(1) != 0) self.advance();
            self.advance();
        }

        if (self.isAtEnd()) return self.errorToken("Unterminated string");

        const tok = self.multilineToken(.string, start_line, start_col);

        // discard closing quote
        self.advance();
        self.resetLength();

        return tok;
    }

    pub fn lexToken(self: *Lexer) Token {
        self.resetLength();

        while (!self.isAtEnd()) {
            const c = self.peek(0);
            self.advance();

            switch (c) {
                ' ', '\t', '\r' => self.resetLength(),
                '\n' => {
                    self.incrLine();
                    self.resetLength();
                },
                '(' => return self.token(.left_paren),
                ')' => return self.token(.right_paren),
                ';' => return self.comment(),
                '"' => return self.string(),
                else => return self.literal(),
            }
        }

        return self.token(.eof);
    }
};
