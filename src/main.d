import std.stdio;
import std.file;

import ddmd.permissivevisitor;
import ddmd.transitivevisitor;

import ddmd.tokens;
import ddmd.root.outbuffer;

import ddmd.parse;
import ddmd.astbase;

import ddmd.id;
import ddmd.globals;
import ddmd.identifier;

extern(C++) class ImportVisitor2(AST) : TransitiveVisitor!AST {
    alias visit = TransitiveVisitor!AST.visit;

    override void visit(AST.Import imp) {
        if (imp.isstatic)
            printf("static ");

        printf("import ");

        if (imp.packages && imp.packages.dim)
            foreach (const pid; *imp.packages)
                printf("%s.", pid.toChars());

        printf("%s", imp.id.toChars());

        if (imp.names.dim) {
            printf(" : ");
            foreach (const i, const name; imp.names) {
                if (i) printf(", ");
                printf("%s", name.toChars());
            }
        }

        printf(";");
        printf("\n");
    }
}

void main() {
    string path = "tests";
    string regex = "*.d";

    auto dFiles = dirEntries(path, regex, SpanMode.depth);
    foreach (f; dFiles) {
        string fn = f.name;
        //writeln("Processing ", fn);

        Id.initialize();
        global._init();
        global.params.isLinux = true;
        global.params.is64bit = (size_t.sizeof == 8);
        global.params.useUnitTests = true;
        ASTBase.Type._init();

        auto id = Identifier.idPool(fn);
        auto m = new ASTBase.Module(&(fn.dup)[0], id, false, false);
        auto input = readText(fn);

        //writeln("Started parsing...");
        scope p = new Parser!ASTBase(m, input, false);
        p.nextToken();
        m.members = p.parseModule();
        //writeln("Finished parsing. Starting transitive visitor");

        scope vis = new ImportVisitor2!ASTBase();
        m.accept(vis);

        //writeln("Finished!");
    }
}
