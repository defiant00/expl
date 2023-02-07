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
        if (index < self.source.len) {
            return self.source[index];
        }
        return 0;
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

    fn identifier(self: *Lexer) Token {
        while (!self.isAtEnd()) {
            switch (self.peek(0)) {
                ' ', '\t', '\r', '\n', '(', ')', ';' => break,
                else => self.advance(1),
            }
        }
        return self.token(.identifier);
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
                else => return self.identifier(),
            }
        }

        return self.token(.eof);
    }
};
