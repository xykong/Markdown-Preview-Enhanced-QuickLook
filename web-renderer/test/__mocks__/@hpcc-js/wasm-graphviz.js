const mockGraphviz = {
    dot: jest.fn().mockReturnValue('<svg xmlns="http://www.w3.org/2000/svg"><g/></svg>'),
};
const Graphviz = {
    load: jest.fn().mockResolvedValue(mockGraphviz),
};
module.exports = { Graphviz };
