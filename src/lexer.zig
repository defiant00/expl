const std = @import("std");
const out = @import("out.zig");

pub const TokenType = enum {
    left_paren,
    right_paren,
    identifier,
    number,
    string,
    error_,
    eof,
};

pub const Token = struct {
    type: TokenType,
    value: []const u8,
    positon: usize,
};

pub const Lexer = struct {
    source: []const u8,
    start: usize,
    current: usize,

    pub fn init(source: []const u8) Lexer {
        return .{
            .source = source,
            .start = 0,
            .current = 0,
        };
    }

    pub fn isAtEnd(self: *Lexer) bool {
        return self.current >= self.source.len;
    }

    fn advance(self: *Lexer, count: usize) void {
        self.current += count;
        if (self.isAtEnd()) self.current = self.source.len;
    }

    fn peek(self: *Lexer, offset: usize) u8 {
        const index = self.current + offset;
        return if (index < self.source.len) self.source[index] else 0;
    }

    fn resetLength(self: *Lexer) void {
        self.start = self.current;
    }

    fn token(self: *Lexer, token_type: TokenType) Token {
        return .{
            .type = token_type,
            .value = self.source[self.start..self.current],
            .positon = self.start,
        };
    }

    fn errorToken(self: *Lexer, message: []const u8) Token {
        return .{
            .type = .error_,
            .value = message,
            .positon = self.start,
        };
    }

    fn isDecimal(c: u8) bool {
        return switch (c) {
            '0'...'9', '_' => true,
            else => false,
        };
    }

    fn isDigit(c: u8) bool {
        return switch (c) {
            '0'...'9' => true,
            else => false,
        };
    }

    fn isIdentifier(c: u8) bool {
        return switch (c) {
            ' ', '\t', '\r', '\n', '(', ')', ';', 0 => false,
            else => true,
        };
    }

    fn identifier(self: *Lexer, first: u8) Token {
        var number = isDigit(first);

        // accept numbers
        if (number) {
            while (isDecimal(self.peek(0))) self.advance(1);

            if (self.peek(0) == '.' and isDecimal(self.peek(1))) {
                // accept the . and digit
                self.advance(2);

                while (isDecimal(self.peek(0))) self.advance(1);
            }
        }

        // if any other characters are encountered then it's an identifier
        if (isIdentifier(self.peek(0))) {
            number = false;
            self.advance(1);

            while (isIdentifier(self.peek(0))) self.advance(1);
        }

        return self.token(if (number) .number else .identifier);
    }

    fn string(self: *Lexer) Token {
        // discard opening quote
        self.resetLength();

        while (self.peek(0) != '"' and !self.isAtEnd()) {
            if (self.peek(0) == '\\' and self.peek(1) != 0) self.advance(1);
            self.advance(1);
        }

        if (self.isAtEnd()) return self.errorToken("Unterminated string.");

        const tok = self.token(.string);

        // discard closing quote
        self.advance(1);
        self.resetLength();

        return tok;
    }

    pub fn lexToken(self: *Lexer) Token {
        self.resetLength();

        while (!self.isAtEnd()) {
            const c = self.peek(0);
            self.advance(1);

            switch (c) {
                ' ', '\t', '\r', '\n' => self.resetLength(),
                '(' => return self.token(.left_paren),
                ')' => return self.token(.right_paren),
                ';' => {
                    while (self.peek(0) != '\n' and !self.isAtEnd()) self.advance(1);
                    self.resetLength();
                },
                '"' => return self.string(),
                else => return self.identifier(c),
            }
        }

        return self.token(.eof);
    }
};
