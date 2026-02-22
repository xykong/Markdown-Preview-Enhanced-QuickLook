const compile = jest.fn().mockReturnValue({ spec: { $schema: 'https://vega.github.io/schema/vega/v5.json', marks: [] } });
module.exports = { compile };
